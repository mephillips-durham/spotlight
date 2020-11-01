# frozen_string_literal: true

module Spotlight
  ##
  # Index and read actions for browse (see {Spotlight::SearchesController}
  # for the curator's create-update-delete actions)
  class BrowseController < Spotlight::ApplicationController
    load_and_authorize_resource :exhibit, class: 'Spotlight::Exhibit'
    include Spotlight::Catalog
    include Blacklight::Facet

    load_and_authorize_resource :search, except: :index, through: :exhibit, parent: false
    before_action :attach_breadcrumbs
    before_action :attach_search_breadcrumb, only: :show
    record_search_parameters only: :show

    helper_method :should_render_spotlight_search_bar?

    before_action :swap_actions_configuration, only: :show

    before_action do
      blacklight_config.track_search_session = false
    end

    def index
      @searches = @exhibit.searches.published
    end

    def show
      @response, @document_list = search_service.search_results do |builder|
        builder.with(search_query)
      end

      respond_to do |format|
        format.html
        format.json do
          @presenter = Blacklight::JsonPresenter.new(@response, blacklight_config)
          render template: 'catalog/index'
        end
      end
    end

    protected

    def swap_actions_configuration
      blacklight_config.index.document_actions = blacklight_config.browse.document_actions
    end

    def search_query
      @search.query_params['q'] = [@search.query_params['q'], params[:browse_q]].join(' ')
      @search.merge_params_for_search(params, blacklight_config)
    end

    ##
    # Browsing an exhibit should start a new search session
    def start_new_search_session?
      params[:action] == 'show'
    end

    # WARNING: Blacklight::Catalog::SearchContext sets @searches in history_session in a before_filter
    # See https://github.com/projectblacklight/blacklight/pull/780
    def history_session
      # nop
    end

    def attach_breadcrumbs
      add_breadcrumb t(:'spotlight.curation.nav.home', title: @exhibit.title), @exhibit
      add_breadcrumb(@exhibit.main_navigations.browse.label_or_default, exhibit_browse_index_path(@exhibit))
    end

    def attach_search_breadcrumb
      add_breadcrumb @search.full_title, exhibit_browse_path(@exhibit, @search)
    end

    def _prefixes
      @_prefixes ||= super + ['catalog']
    end

    def current_masthead
      if resource_masthead?
        @search.masthead
      else
        super
      end
    end

    def resource_masthead?
      @search&.masthead && @search.masthead.display?
    end

    # This is overidden for the browse controller context from where it is defined in a helper
    # (which just checks if the current exhibit is searchable) in order to also prevent showing the search bar
    # if the current browse category is configured to display its masthead
    def should_render_spotlight_search_bar?
      current_exhibit&.searchable? && !resource_masthead?
    end

    def document_index_view_type
      return super if params[:view].present?

      if @search && @search.default_index_view_type.present?
        blacklight_config.view[@search.default_index_view_type].key
      else
        default_document_index_view_type
      end
    end

    helper_method :document_index_view_type

    def default_document_index_view_type
      if view_available? default_browse_index_view_type
        default_browse_index_view_type
      else
        super
      end
    end

    def view_available?(view)
      blacklight_config.view.key?(view) && blacklight_configuration_context.evaluate_if_unless_configuration(blacklight_config.view)
    end

    def default_browse_index_view_type
      Spotlight::Engine.config.default_browse_index_view_type
    end

    def render_save_this_search?
      false
    end
  end
end
