require_relative "db/db"
require_relative "helpers/app_helpers"
require_relative "helpers/view_helpers"
require_relative "helpers/mail_helpers"

module WeightTracker

  class App < Roda

    opts[:root] = File.dirname(__FILE__)

    # General plugins
    plugin :environments
    unless test?
      plugin :enhanced_logger,
        filter: ->(path) { path.start_with?("/assets") },
        trace_missed: true
    end

    include AppHelpers
    include ViewHelpers
    
    # Security
    secret = ENV["SESSION_SECRET"]
    plugin :sessions, key: "weight_tracker.session", secret: secret
    plugin :route_csrf
    plugin :rodauth do
      enable :login, :logout, :create_account, :change_login, :change_password,
        :change_password_notify, :close_account, :active_sessions, :audit_logging,
        :reset_password, :verify_account, :verify_account_grace_period, :lockout,
        :verify_login_change
      
      # Base
      account_password_hash_column :password_hash
      hmac_secret secret
      title_instance_variable :@page_title
      
      # Email Base
      email_from "weighttracker@example.com"
      email_subject_prefix "WeightTracker - "
      send_email { |mail| MailHelpers.send_mail_with_sendgrid(mail) } if App.production?

      # Create Account
      before_create_account do
        unless user_name = param_or_nil("user_name")
          throw_error_status(422, "user_name", "must be present")
        end
        unless user_name.length > 2
          throw_error_status(422, "user_name", "must have at least 3 characters")
        end
        account[:user_name] = user_name
      end
      
      # Login
      login_redirect "/entries"
      
      # Change Login
      change_login_redirect { "/accounts/#{account_from_session[:id]}" }

      # Change Password
      change_password_redirect { "/accounts/#{account_from_session[:id]}" }
      
      # Close Account
      before_close_account do
        unless param_or_nil("confirm-delete-data") == "confirm"
          flash[:error] = "You did not confirm you made a backup of your data"
          scope.request.redirect close_account_path
        end
      end

      # Audit Logging
      audit_log_metadata_default do
        {"ip" => scope.request.ip}
      end

      # Lockout
      max_invalid_logins 10
      unlock_account_email_body { scope.render "mails/unlock-account-email" }

      # Verify Login Change
      verify_login_change_button "Verify Email Change"
      change_login_needs_verification_notice_flash "An email has been sent to your new email verify it"
      verify_login_change_notice_flash "Your new email has been verified"
      verify_login_change_email_body do
        scope.render "mails/verify-email-change-email",
                     locals: { old_email: account[:email], new_email: verify_login_change_new_login }
      end

      # Reset Password
      reset_password_email_subject "Reset Password Link"
      reset_password_email_body { scope.render "mails/reset-password-email" }
      reset_password_email_sent_redirect "/login"
      reset_password_email_sent_notice_flash "An Email has been sent to reset your password"
      reset_password_redirect "/entries"
      reset_password_email_recently_sent_redirect "/login"
      reset_password_autologin? true

      # Change Password Notify
      password_changed_email_subject { "Password Modified" }
      password_changed_email_body { scope.render "mails/change-password-notify" }

      # Verify Account
      verify_account_email_sent_notice_flash "An email has been sent to you to verify your account"
      verify_account_email_subject "Verify your account"
      verify_account_email_body { scope.render "mails/verify-account-email" }
    end

    plugin :content_security_policy do |csp|
      csp.default_src :self
      csp.font_src :self, "fonts.gstatic.com"
      csp.img_src :self
      csp.object_src :self
      csp.frame_src :self
      csp.style_src :self, "fonts.googleapis.com", "stackpath.bootstrapcdn.com"
      csp.form_action :self
      csp.script_src :self
      csp.connect_src :self
      csp.base_uri :none
      csp.frame_ancestors :self
      csp.upgrade_insecure_requests true
    end

    # The Default Headers plugin must come after the csp plugin, otherwise don't work
    plugin :default_headers, "Strict-Transport-Security" => "max-age=63072000; includeSubDomains",
      "X-Content-Type-Options" => "nosniff"

    # Routing
    plugin :status_handler

    status_handler(404) do
      view "error_404"
    end

    status_handler(403) do
      view "error_403"
    end

    # Rendering
    plugin :render, engine: "haml", template_opts: {escape_html: true}
    plugin :partials
    plugin :assets,
      css: %w[lg_utilities_20201112.css style.css],
      js: {main: "main.js", close_account: "close_account.js"},
      group_subdirs: false,
      gzip: true
    compile_assets if production?
    plugin :public, gzip: true
    plugin :flash
    plugin :content_for

    # Request / response
    plugin :typecast_params
    alias_method :tp, :typecast_params
    plugin :sinatra_helpers
    
    
    Mail.defaults { delivery_method :smtp, address: "localhost", port: 1025 } if App.development?
    Mail.defaults { delivery_method :test } if App.test?


    route do |r|
      r.public if App.production?
      r.assets unless App.production?
      r.rodauth
      check_csrf!
      rodauth.check_active_session
      rodauth.require_authentication
      @account_ds = rodauth.account_from_session

      r.root do
        r.redirect "entries/new"
      end

      r.is "change-user-name" do
        r.get do
          view "change-user-name"
        end

        r.post do
          account = Account[@account_ds[:id]]
          account.set(user_name: r.params["user_name"])
          if account.valid?
            account.save
            flash[:notice] = "User Name successfully changed"
            r.redirect "/accounts/#{account[:id]}"
          else
            flash[:error] = format_flash_error(account)
            r.redirect
          end
        end
      end

      r.is "export-data" do
        r.get do
          view "export_data"
        end

        r.post do
          @data = Entry.where(account_id: @account_ds[:id]).order(:id).select(:day, :weight, :note)

          if r.params["file_format"] == "json"
            file_name = "wt_data_#{@account_ds[:user_name]}_#{Time.now.strftime("%Y%m%d%H%M%S")}.json"
            data_file_path = File.join(opts[:root], "tmp", file_name)
            File.open(data_file_path, "w") { |f| f.write @data.to_json }
            send_file data_file_path, type: "application/json", filename: file_name
          elsif r.params["file_format"] == "csv"
            file_name = "wt_data_#{@account_ds[:user_name]}_#{Time.now.strftime("%Y%m%d%H%M%S")}.csv"
            data_file_path = File.join(opts[:root], "tmp", file_name)
            File.open(data_file_path, "w") { |f| f.write @data.to_csv(write_headers: true) }
            send_file data_file_path, type: "text/csv", filename: file_name
          elsif r.params["file_format"] == "xml"
            file_name = "wt_data_#{@account_ds[:user_name]}_#{Time.now.strftime("%Y%m%d%H%M%S")}.xml"
            data_file_path = File.join(opts[:root], "tmp", file_name)
            File.open(data_file_path, "w") { |f| f.write @data.to_xml }
            send_file data_file_path, type: "text/xml", filename: file_name
          else
            flash.now[:error] = "The file format you requested does not exist"
            response.status = 400
            r.halt
          end
        end
      end

      r.get "security-log" do
        @security_logs = DB[:account_authentication_audit_logs]
                          .where(account_id: @account_ds[:id])
                          .reverse(:id)
                          .select_map([:at, :message, :metadata])

        view "security_log"
      end

      r.get "accounts", Integer do |account_id|
        if (@account = Account[account_id.to_i]) && (account_id == @account_ds[:id] || is_admin?(@account_ds))
          view "account_show"
        elsif @account
          flash.now["error"] = "You're not authorized to see this page"
          response.status = 403
          r.halt
        else
          response.status = 404
          r.halt
        end
      end

      r.on "entries" do
        r.is do
          r.get do
            @entries = Entry.all_desc_with_deltas(@account_ds[:id])

            view "entries_index"
          end

          r.post do
            submitted = {day: tp.date("day"),
                         weight: tp.float("weight"),
                         note: tp.str("note"),
                         account_id: @account_ds[:id]}

            @entry = Entry.new
            @entry.set(submitted)

            if @entry.valid?
              @entry.save
              flash[:notice] = "New entry saved"
              r.redirect
            else
              flash.now["error"] = format_flash_error(@entry)
              view "entries_new"
            end
          end
        end

        r.is "new" do
          @entry = Entry.new
          @most_recent_weight = Entry.most_recent_weight(@account_ds[:id])

          view "entries_new"
        end

        r.on Integer do |id|
          @entry = Entry[id]

          r.is do
            r.post do
              submitted = {day: tp.date("day"),
                           weight: tp.float("weight"),
                           note: tp.str("note"),
                           account_id: @account_ds[:id]}

              @entry.set(submitted)

              if @entry.valid?
                @entry.save
                flash[:notice] = "Entry has been updated"
                r.redirect "/entries"
              else
                flash.now[:error] = @entry.errors.values.join("\n")
                view "entries_edit"
              end
            end
          end

          r.get "edit" do
            view "entries_edit"
          end

          r.post "delete" do
            @entry.delete

            r.redirect "/entries"
          end
        end
      end
    end
  end
end
