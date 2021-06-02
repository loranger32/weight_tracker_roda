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
          @batch = Batch.new(account_id: @account_ds[:id], active: false)

          submitted = {name: tp.str("name"), target: tp.str("target")}
          @batch.set(submitted)

          if @batch.valid? && valid_weight_string?(submitted[:target])
            @batch.set_active_status
            @batch.save
            flash["notice"] = "Batch successfully created"
          elsif !valid_weight_string?(submitted[:target])
            flash["error"] = "Invalid target weight, must be between 20.0 and 999.9"
          else
            flash["error"] = format_flash_error(@batch)
          end
          r.redirect
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
            submitted = {name: tp.str("name"), target: tp.str("target")}

            @batch.set(submitted)

            if @batch.valid? && valid_weight_string?(submitted[:target])
              @batch.set_active_status if r.params["confirm-make-batch-active"] == "confirm"
              @batch.save
              flash["notice"] = "Batch has been successfully updated"
              r.redirect "/batches"
            elsif !valid_weight_string?(submitted[:target])
              flash.now["error"] = "Invalid target weight, must be between 20.0 and 999.9"
              view "batch_edit"
            else
              flash.now["error"] = format_flash_error(@batch)
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
            flash["notice"] = "Batch has been successfully deleted"
            r.redirect "/batches"
          else
            flash["error"] = "Please tick the checkbox to confirm batch deletion"
            r.redirect "edit"
          end
        end
      end
    end
  end
end
