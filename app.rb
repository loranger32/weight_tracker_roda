require_relative 'db/db'

module WeightTracker
class App < Roda
  opts[:root] = File.dirname(__FILE__)

  logger = $stderr
  plugin :common_logger, logger unless ENV['RACK_ENV'] == 'test'

  # Security
  secret = ENV['SESSION_SECRET']
  plugin :sessions, key: 'weight_tracker.session', secret: secret
  plugin :content_security_policy do |csp|
    csp.default_src :self
    csp.font_src :self, 'fonts.gstatic.com'
    csp.img_src :self
    csp.object_src :self
    csp.frame_src :self
    csp.style_src :self, 'fonts.googleapis.com', 'stackpath.bootstrapcdn.com'
    csp.form_action :self
    csp.script_src :self
    csp.connect_src :self
    csp.base_uri :none
    csp.frame_ancestors :self
    csp.upgrade_insecure_requests
    csp.block_all_mixed_content
  end
  plugin :route_csrf
  plugin :rodauth do
    enable :login, :logout, :create_account, :change_login, :change_password, 
           :close_account, :active_sessions
    skip_status_checks? true
    account_password_hash_column :password_hash
    hmac_secret secret
    prefix '/auth'
    title_instance_variable :@page_title
    login_redirect '/entries'
    before_create_account do
      unless user_name = param_or_nil("user_name")
        throw_error_status(422, "user_name", "must be present")
      end
      account[:user_name] = user_name
    end
    after_login do
      logger.write "#{account[:email]} logged in!"
    end
    before_close_account do
      unless param_or_nil("confirm-delete-data") == "confirm"
        flash[:error] = "You did not confirm you made a backup of your data"
        scope.request.redirect close_account_path
      end
    end
    close_account_redirect "/auth/login"
  end

  # Routing

  plugin :status_handler

  status_handler(404) do
    view "error_404"
  end

  # Rendering
  plugin :render, engine: 'haml', template_opts: { escape_html: true }
  plugin :partials
  plugin :assets,
    css: %w[lg_utilities_20201112.css style.css],
    js: {main: "main.js", close_account: "close_account.js"},
    group_subdirs: false,
    gzip: true
  plugin :public, gzip: true
  plugin :flash
  plugin :content_for

  # Request / response
  plugin :typecast_params
  alias_method :tp, :typecast_params


  route do |r|
    r.public
    r.assets


    r.on "auth" do
      r.rodauth
      r.is "change_user_name" do
        rodauth.require_authentication

        r.get do
          view "change-user-name"
        end

        r.post do
          check_csrf!
          account = Account[rodauth.account_from_session[:id]]
          account.set(user_name: r.params["user_name"])
          if account.valid?
            account.save
            flash[:notice] = "User Name successfully changed"
            r.redirect "/accounts/#{account[:id]}"
          else
            flash[:error] = account.errors.values.join("\n")
            r.redirect
          end
        end
      end
    end
    
    rodauth.check_active_session
    rodauth.require_authentication
    check_csrf!

    r.root do
      r.redirect 'entries/new'
    end

    r.on "accounts" do
      r.get Integer do |account_id|
        @account = Account[account_id.to_i]
        view 'account_show'
      end
    end

    r.on "entries" do
      r.is do
        r.get do
          @entries = Entry.all_desc_with_deltas

          view 'entries_index'
        end

        r.post do
          submitted = { day: tp.date('day'),
                        weight: tp.float('weight'),
                        note: tp.str('note') }

          errors = validate_entry_params(submitted)

          if errors.empty?
            Entry.insert(submitted)
            r.redirect
          else
            render 'entries_new'
          end
        end
      end

      r.is 'new' do
        @entry = Entry.new
        @most_recent_weight = Entry.most_recent_weight

        view 'entries_new'
      end

      r.on Integer do |id|
        @entry = Entry[id]

        r.is do
          r.post do
            submitted = { day: tp.date('day'),
                          weight: tp.float('weight'),
                          note: tp.str('note') }

            errors = validate_entry_params(submitted)

            if errors.empty?
              @entry.update(submitted)
              r.redirect '/entries'
            else
              render 'entries_edit'
            end 
          end
        end

        r.get 'edit' do
          view 'entries_edit'
        end

        r.post 'delete' do
          @entry.delete

          r.redirect '/entries'
        end
      end
    end
  end
end
end
