require_relative "db/db"

Dir["helpers/*.rb"].each { require_relative _1 }
Dir["jobs/*.rb"].each { require_relative _1 }

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
      :reset_password, :reset_password_notify, :verify_account,
      :verify_account_grace_period, :lockout, :verify_login_change, :otp, :recovery_codes,
      :internal_request

    # Base
    account_password_hash_column :password_hash
    hmac_secret secret
    title_instance_variable :@page_title
    login_label "Email"
    if App.production?
      domain ENV["DOMAIN"]
    elsif App.development?
      domain "localhost"
    elsif App.test?
      domain "www.example.com"
    end

    # Email Base
    email_from ENV["WT_EMAIL"]
    email_subject_prefix "WeightTracker - "
    send_email { SendEmailJob.perform_async(_1) } if App.production?

    # Login Password Requirements Base
    password_hash_cost(App.test? ? 2 : 12)

    # Create Account
    create_account_additional_form_tags { scope.render("rodauth/create_account_aft") }
    before_create_account do
      unless (user_name = param_or_nil("user_name"))
        throw_error_status(422, "user_name", "must be present")
      end
      unless user_name.length > 2
        throw_error_status(422, "user_name", "must have at least 3 characters")
      end
      account[:user_name] = user_name
    end

    # Send email to admin when a new user signs up (not in test - complicates tests and not major feature)
    unless App.test?
      after_create_account do
        mail = Mail.new do
          from ENV["WT_EMAIL"]
          to ENV["MY_EMAIL"]
          subject "WeightTracker - New User Signed Up"
          body "A new user signed up"
        end
        SendEmailJob.perform_async(mail)
      end
    end

    # Login
    login_redirect "/"
    after_login { TruncateAuditLogsJob.perform_async(account[:id]) }

    # Change Login
    change_login_redirect { "/account" }
    change_login_additional_form_tags { scope.render("rodauth/change_login_aft", locals: {current_email: account[:email]}) }
    change_login_button "Change Email"

    # Change Password
    change_password_redirect { "/account" }
    change_password_additional_form_tags { scope.render("rodauth/change_password_aft") }

    # Close Account
    before_close_account do
      unless param_or_nil("confirm-delete-data") == "confirm"
        flash[:error] = "You did not confirm you made a backup of your data"
        scope.request.redirect close_account_path
      end
    end

    # Active Session
    session_inactivity_deadline 216000 # 60 hours

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
        locals: {old_email: account[:email], new_email: verify_login_change_new_login}
    end

    # Reset Password
    reset_password_additional_form_tags { scope.render("rodauth/reset_password_aft") }
    reset_password_email_subject "Reset Password Link"
    reset_password_email_body { scope.render "mails/reset-password-email" }
    reset_password_email_sent_redirect "/login"
    reset_password_email_sent_notice_flash "An Email has been sent to reset your password"
    reset_password_redirect "/entries"
    reset_password_email_recently_sent_redirect "/login"
    reset_password_autologin? true

    # Reset Password Notify
    reset_password_notify_email_subject "Your Password has been reset"
    reset_password_notify_email_body { scope.render "mails/reset-password-notify-email" }

    # Change Password Notify
    password_changed_email_subject { "Password Modified" }
    password_changed_email_body { scope.render "mails/change-password-notify" }

    # Verify Account
    verify_account_email_sent_notice_flash "An email has been sent to you to verify your account"
    verify_account_email_subject "Verify your account"
    verify_account_email_body { scope.render "mails/verify-account-email", locals: {rodauth: self} }
    verify_account_email_sent_redirect "/login"

    # Two Factor Base Setup
    two_factor_disable_button "Remove 2FA"
    two_factor_disable_redirect { "/account" }
    two_factor_need_authentication_error_flash nil
    two_factor_disable_additional_form_tags { scope.render("rodauth/multifactor_disable_aft") }

    # Recovery Codes Setup
    auto_add_recovery_codes? true
    auto_remove_recovery_codes? true

    internal_request_configuration do
      if App.production?
        domain ENV["DOMAIN"]
      elsif App.development?
        domain "localhost:9292"
      elsif App.test?
        domain "www.example.com"
      end
    end
  end

  plugin :default_headers,
    "Strict-Transport-Security" => "max-age=63072000; includeSubDomains",
    "X-Content-Type-Options" => "nosniff",
    "X-Frame-Options" => "deny",
    "X-XSS-Protection" => "1; mode=block"

  plugin :content_security_policy do |csp|
    csp.default_src :none
    csp.font_src :self
    csp.img_src :self, "data:" # data: is required for Bootstrap 5 svg inline icons, for the moment
    csp.object_src :none
    csp.frame_src :self
    csp.style_src :self, "fonts.googleapis.com", "stackpath.bootstrapcdn.com", "cdn.jsdelivr.net/npm/bootstrap@5.2.2/dist/css/bootstrap.min.css"
    csp.form_action :self
    csp.script_src :self, "cdn.jsdelivr.net/npm/bootstrap@5.2.2/dist/js/bootstrap.bundle.min.js", "https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.7.1/chart.min.js"
    csp.connect_src :self
    csp.base_uri :none
    csp.frame_ancestors :none
    csp.block_all_mixed_content
  end

  # Routing
  plugin :hash_routes
  Dir["routes/*.rb"].each { require_relative _1 }

  plugin :status_handler

  [400, 404, 403, 500].each do |error_code|
    status_handler(error_code) { view "errors/error_#{error_code}" }
  end

  # Rendering
  plugin :render, engine: "haml", template_opts: {escape_html: true}
  plugin :partials
  plugin :assets,
    css: %w[fonts.css bootstrap_5_3_2.min.css style.css],
    js: {main: "main.js", progress_bar: "progress-bar.js",
         close_account: "close_account.js", recovery_codes: "recovery_codes.js",
         entries_edit: "entries_edit.js", batch_index: "batch_index.js",
         batch_edit: "batch_edit.js", admin_actions: "admin_actions.js",
         bs_tooltip: "bs_tooltip.js", entries_index_charts: "entries_index_charts.js",
         chartjs: "chartjs_4_4_1.min.js", htmx: "htmx_1_9_6.js", bootstrap: "bootstrap_5_3_2.bundle.min.js"},
    group_subdirs: false,
    gzip: true,
    timestamp_paths: true
  compile_assets if production?
  plugin :public, gzip: true
  plugin :flash
  plugin :content_for

  # Request / response
  plugin :typecast_params
  alias_method :tp, :typecast_params
  plugin :sinatra_helpers

  # Mail
  production_smtp_options = {
    address: ENV["SMTP_ADDRESS"],
    port: ENV["SMTP_PORT"],
    domain: ENV["SMTP_DOMAIN"],
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    authentication: :plain,
    enable_starttls: true,
  }

  development_smtp_options = {
    address: "localhost",
    port: 1025
  }

  Mail.defaults do
    if App.production?
      delivery_method :smtp, production_smtp_options
    elsif App.development?
      delivery_method :smtp, development_smtp_options
    elsif App.test?
      delivery_method :test
    end
  end

  route do |r|
    r.public
    r.assets unless App.production?

    r.get "about" do
      about_text = File.read("README.md")
      @html = Kramdown::Document.new(about_text).to_html

      view "about"
    end

    check_csrf!
    r.rodauth
    rodauth.check_active_session
    rodauth.require_authentication
    @account_ds = rodauth.account_from_session

    ensure_mensuration_is_setup_for_account(@account_ds[:id])
    ensure_at_least_one_batch_for_account!(@account_ds[:id])

    r.hash_branches

    r.root do
      r.redirect landing_page(@account_ds)
    end

    r.is "change-user-name" do
      r.get do
        view "change-user-name"
      end

      r.post do
        account = Account[@account_ds[:id]]
        account.set(user_name: h(tp.str("user_name")))
        if account.valid?
          account.save
          flash["notice"] = "User Name successfully changed"
          r.redirect "/account"
        else
          flash["error"] = format_flash_error(account)
          r.redirect
        end
      end
    end

    r.is "export-data" do
      r.get do
        view "export_data"
      end

      r.post do
        @raw_entry_data = Entry.where(account_id: @account_ds[:id])
          .order(:id)
          .select(:day, :weight, :note, :batch_id, :alcohol_consumption, :sport)
        @raw_batch_data = Batch.where(account_id: @account_ds[:id])
          .order(:id)
          .select(:id, :name, :target)

        # Hack to ensure proper encoding of notes
        @raw_entry_data_with_decrypted_notes = @raw_entry_data.all.map do |ds_entry|
          ds_entry[:note] = ds_entry.note.force_encoding("UTF-8")
          ds_entry
        end

        # Hack to ensure proper encoding of name
        @raw_batch_data_with_decrypted_name = @raw_batch_data.all.map do |ds_batch|
          ds_batch[:name] = ds_batch.name.force_encoding("UTF-8")
          ds_batch
        end

        file_name = "wt_data_#{@account_ds[:user_name]}_#{Time.now.strftime("%Y%m%d%H%M%S")}.json"
        data_file_path = File.join(opts[:root], "tmp", file_name)
        File.open(data_file_path, "w") do |f|
          combined = "["
          combined << @raw_entry_data_with_decrypted_notes.to_json
          combined << ","
          combined << @raw_batch_data_with_decrypted_name.to_json
          combined << "]"
          f.write combined
        end
        send_file data_file_path, type: "application/json", filename: file_name
      end
    end

    r.get "security-log" do
      current_page = tp.pos_int("page", 1)

      @security_logs = DB[:account_authentication_audit_logs]
        .where(account_id: @account_ds[:id])
        .reverse(:id)
        .extension(:pagination)
        .paginate(current_page, 30)

      view "security_log"
    end

    r.get "account" do
      @account = Account[@account_ds[:id]]
      view "account_show"
    end
  end
end
