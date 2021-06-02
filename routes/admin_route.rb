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
          case r.params["query"]
          when "verified"   then @accounts = Account.verified
          when "unverified" then @accounts = Account.unverified
          when "closed"     then @accounts = Account.closed
          when "otp_on"     then @accounts = Account.otp_on
          when "otp_off"    then @accounts = Account.otp_off
          when "admin"      then @accounts = Account.admins
          else
            @accounts = Account.all
          end
          view "admin/accounts", layout: "layout-admin"
        end

        # Verify and Delete branches setup

        account_id = tp.int("account_id")
          
        unless account_id > 0 && @target_account = Account[account_id]
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

        r.is "verify" do
          unless @target_account.is_unverified?
            flash["error"] = "This account is already verified"
            r.redirect "/admin/accounts"
          end

          r.get do
            view "/admin/account-verify", layout: "layout-admin"
          end

          r.post do
            @target_account.update(status_id: 2)
            DB[:account_verification_keys].where(id: @target_account.id).delete
            flash["notice"] = "Account successfully verified"
            r.redirect "/admin/accounts"
          end
          
        end

        r.is "delete" do
          r.get do
            view "admin/account-delete", layout: "layout-admin"
          end

          r.post do
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
