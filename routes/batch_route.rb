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
          @batch.set_active_status(true)

          if @batch.valid?
            @batch.save
            flash["notice"] = "Batch successfully created"
            r.redirect
          else
            currently_active_batch.set_active_status(true)
            flash["error"] = format_flash_error(@batch)
            r.redirect "/batches"
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

            @batch.set_active_status(r.params["confirm-make-batch-active"] == "confirm")

            if @batch.valid?
              @batch.save
              flash[:notice] = "The batch has been successfully updated"
              r.redirect "/batches"
            else
              flash[:error] = "There was a problem with the batch update"
              view "/batch/#{@batch.id}/edit"
            end
          end
        end

        r.is "edit" do
          view "batch_edit"
        end

        r.post "delete" do
          @batch.delete
          flash[:notice] = "batch has been successfully deleted"
          r.redirect "/batches"
        end
      end
    end
  end
end
