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
          else
            @accounts = Account.all
          end
          view "admin/accounts", layout: "layout-admin"
        end

        r.is "delete" do
          account_id = tp.int("account_id")
            
          unless account_id != 0 && @target_account = Account[account_id]
            response.status = 404
            r.halt
          end

          r.get do
            view "admin/account-delete", layout: "layout-admin"
          end

          r.post do
            @target_account.destroy
            flash["success"] = "Account successfully deleted"
            r.redirect "/admin/accounts"
          end
        end
      end
    end
  end
end
