require_relative 'db/db'

module WeightTracker
class App < Roda
  opts[:root] = File.dirname(__FILE__)

  # Security
  plugin :sessions, key: 'weight_tracker.session', secret: ENV['SESSION_SECRET']
  plugin :content_security_policy do |csp|
    csp.default_src :none
    csp.img_src :self
    csp.object_src :self
    csp.frame_src :self
    csp.style_src :self
    csp.form_action :self
    csp.script_src :self
    csp.connect_src :self
    csp.base_uri :none
    csp.frame_ancestors :self
    csp.upgrade_insecure_requests
    csp.block_all_mixed_content
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
    js: %w[main.js],
    group_subdirs: false
  plugin :public
  plugin :flash

  # Request / response
  plugin :typecast_params
  alias_method :tp, :typecast_params

  route do |r|
    r.assets

    r.public

    r.root do
      r.redirect 'entries/new'
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
