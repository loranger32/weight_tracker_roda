module WeightTracker
  class App
    hash_branch("admin") do |r|
      unless Account[@account_ds[:id]].is_admin?
        response.status = 403
        r.halt
      end

      rodauth.require_two_factor_setup
      rodauth.require_authentication
      @page_title = "Admin - "

      r.is do
        r.redirect "/admin/accounts"
      end

      r.on "accounts" do
        r.is do
          @clicked_link = tp.str("query")
          @accounts = case @clicked_link
          when "verified" then Account.verified
          when "unverified" then Account.unverified
          when "closed" then Account.closed
          when "otp_on" then Account.otp_on
          when "otp_off" then Account.otp_off
          when "admin" then Account.admins
          else
            Account.all
          end
          view "admin/accounts", layout: "layout-admin"
        end

        r.on Integer do |account_id|
          #account_id = account_id.to_i
          unless account_id > 0 && (@target_account = Account[account_id])
            response.status = 404
            r.halt
          end

          # Should only be needed for GET request, beacuse for POST requests
          # it should normally raise a Roda::RodaPlugins::RouteCsrf:InvalidToken error before
          # But extra safety
          if @target_account.is_admin?
            flash["error"] = "Cannot perform this action on admin user"
            r.redirect "/admin/accounts"
          end

          r.get do
            view "/admin/account", layout: "layout-admin"
          end

          r.post "verify" do
            unless @target_account.is_unverified?
              flash["error"] = "This account is already verified"
              r.redirect "/admin/accounts"
            end

            @target_account.update(status_id: 2)
            DB[:account_verification_keys].where(id: @target_account.id).delete
            flash["notice"] = "Account successfully verified"
            r.redirect "/admin/accounts/#{@target_account.id}"
          end

          r.post "close" do
            if @target_account.is_closed?
              flash["error"] = "This account is already closed"
              r.redirect "/admin/accounts"
            end

            @target_account.update(status_id: 3)
            flash["notice"] = "Account successfully closed"
            r.redirect "/admin/accounts/#{@target_account.id}"
          end

          r.post "open" do
            unless @target_account.is_closed?
              flash["error"] = "This account is already open"
              r.redirect "/admin/accounts"
            end

            # Note that (re)opeining an account will set its status to "verified"
            @target_account.update(status_id: 2)
            flash["notice"] = "Account successfully opened and set to verified status"
            r.redirect "/admin/accounts/#{@target_account.id}"
          end

          r.post "delete" do
            unless h(tp.str("confirm-delete-account")) == "confirm"
              flash["error"] = "You did not checked the confirmation checkbox, action cancelled."
              r.redirect "/admin/accounts/#{@target_account.id}"
            end
            
            if @target_account.destroy
              flash["notice"] = "Account successfully deleted"
            else
              flash["error"] = "Could not delete account"
            end

            r.redirect "/admin/accounts"
          end
        end
      end
    end
  end
end
