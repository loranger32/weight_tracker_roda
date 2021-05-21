module WeightTracker
  class App
    hash_branch("batches") do |r|
      # TODO - Ugly - to refactor
      @current_batch = Batch[Account[@account_ds[:id]].active_batch_id]
      
      r.is do
        r.get do
          @batches = Account[@account_ds[:id]].batches
          view "batch_index"
        end

        r.post do
          currently_active_batch = Batch.active_for_account(@account_ds[:id])

          @batch = Batch.new(account_id: @account_ds[:id], name: tp.str("name"))
          @batch.set_active_status

          if @batch.valid?
            @batch.save
            flash["notice"] = "Batch successfully created"
            r.redirect
          else
            currently_active_batch.set_active_status
            flash["error"] = format_flash_error(@batch)
            r.redirect
          end
        end
      end

      r.on Integer do |batch_id|
        @batch = Batch[batch_id]
        
        unless @batch
          response.status = 404
          r.halt
        end

        unless @batch.account_id == @account_ds[:id]
          response.status = 403
          r.halt
        end

        r.is do
          r.post do
            @batch.set(name: tp.str("name"))

            @batch.set_active_status if r.params["confirm-make-batch-active"] == "confirm"

            if @batch.valid?
              @batch.save
              flash[:notice] = "Batch has been successfully updated"
              r.redirect "/batches"
            else
              flash.now[:error] = format_flash_error(@batch)
              view "batch_edit"
            end
          end
        end

        r.is "edit" do
          view "batch_edit"
        end

        r.post "delete" do
          if r.params["confirm-delete-batch"] == "confirm"
            @batch.destroy
            flash[:notice] = "Batch has been successfully deleted"
            r.redirect "/batches"
          else
            flash[:error] = "Please tick the checbox to confirm batch deletion"
            r.redirect "edit"
          end
        end
      end
    end
  end
end
