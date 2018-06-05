# corresponds to a IIIF Annotation List
module BlacklightIiifSearch
  class IiifSearchResponse
    attr_reader :solr_response, :controller

    def initialize(solr_response, parent_id, controller, iiif_search_config)
      @solr_response = solr_response
      @parent_id = parent_id
      @controller = controller
      @iiif_config = iiif_search_config
    end

    def annotation_list
      anno_list = IIIF::Presentation::AnnotationList.new('@id' => anno_list_id)
      anno_list['@context'] = %w[
        http://iiif.io/api/presentation/2/context.json
        http://iiif.io/api/search/1/context.json
      ]
      anno_list['resources'] = resources
      anno_list['within'] = within
      anno_list['next'] = paged_url(solr_response.next_page) if solr_response.next_page
      anno_list['startIndex'] = 0 unless solr_response.total_pages > 1
      anno_list.to_ordered_hash(force: true, include_context: false)
    end

    def anno_list_id
      controller.request.original_url
    end

    def resources
      resources_array = []
      @total = 0
      solr_response['highlighting'].each do |id, hl_hash|
        if hl_hash.empty?
          @total += 1
          resources_array << IiifSearchAnnotation.new(id,
                                                      solr_response.params['q'],
                                                      0, nil,
                                                      controller,
                                                      @parent_id).as_hash
        else
          hl_hash.each_value do |hl_array|
            hl_array.each_with_index do |hl, hl_index|
              @total += 1
              resources_array << IiifSearchAnnotation.new(id,
                                                          solr_response.params['q'],
                                                          hl_index, hl,
                                                          controller,
                                                          @parent_id).as_hash
            end
          end
        end
      end
      resources_array
    end

    def within
      within_hash = IIIF::Presentation::Layer.new
      within_hash['ignored'] = ignored
      if solr_response.total_pages > 1
        within_hash['first'] = paged_url(1)
        within_hash['last'] = paged_url(solr_response.total_pages)
      else
        within_hash['total'] = @total
      end
      within_hash
    end

    def ignored
      relevant_keys = controller.iiif_search_params.keys
      relevant_keys.delete('solr_document_id')
      relevant_keys - @iiif_config[:supported_params]
    end

    def paged_url(page_index)
      controller.solr_document_iiif_search_url(clean_params.merge(page: page_index))
    end

    # returns ActionController::Parameters
    def clean_params
      remove = ignored.map(&:to_sym)
      controller.iiif_search_params.except(*%i[page solr_document_id] + remove)
    end
  end
end
