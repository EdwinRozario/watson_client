# frozen_string_literal: true

module WatsonClient
  # All Watson services defined here
  class Service
    attr_reader :api_docs, :gateways, :doc_urls, :all
    def initialise
      @api_docs = {
        gateway: 'https://gateway.watsonplatform.net',
        gateway_a: 'https://gateway-a.watsonplatform.net',
        doc_base1: 'https://watson-api-explorer.mybluemix.net/',
        doc_base2: 'http://www.ibm.com/watson/developercloud/doc/',
        ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
      }

      update_api_docs

      @gateways = fetch_gateways
      @doc_urls = fetch_doc_urls

      fetch_all_services
    end

    def fetch_gateways
      { gateway: @api_docs.delete(:gateway),
        gateway_a: @api_docs.delete(:gateway_a) }
    end

    def fetch_doc_urls
      { doc_base1: api_docs.delete(:doc_base1),
        doc_base2: api_docs.delete(:doc_base2) }
    end

    def retrieve_docs
      apis  = {}

      

      # Watson Developercloud
      host2 = doc_urls[:doc_base2][%r{^https?:\/\/[^\/]+/}]
      open(doc_urls[:doc_base2], Options, &:read).scan(/<li>\s*<img.+data-src=.+?>\s*<h2><a href="(.+?)".*?>\s*(.+?)\s*<\/a><\/h2>\s*<p>(.+?)<\/p>\s*<\/li>/) do
        api = {'path'=>$1, 'title'=>$2, 'description'=>$3}
        apis[api['title']]['description'] = api['description'] if api['path'] !~ /\.\./ && apis.key?(api['title'])
      end

      apis
    end

    # Retreives docs from Watson API Explorer
    def retrieve_docs_from_host1
      apis = {}
      host = @doc_urls[:doc_base1][%r{^https?:\/\/[^\/]+}]
      apis_received = open(@doc_urls[:doc_base1], @api_docs, &:read).scan(/<a class="swagger-list--item-link" href="\/(.+?)".*?>\s*(.+?)\s*<\/a>/i)
      
      apis_received.each do |path, title|
        begin
          api = { path: "#{@doc_urls[:doc_base1]}#{path}",
                  title: title.sub(/\s*\(.+?\)$/, ''),
                  deprecated: title.include?('(Deprecated)') }

          fetched_path = open(api['path'], Options, &:read).scan(%r{url:\s*'(.+?)'})
          api[:path] = "#{host}#{fetched_path}"
          apis[api[:title]] = api
        rescue OpenURI::HTTPError
          # Some log here
        end
      end

      apis
    end

    def fetch_all_services
      @all = []

      # yet to be written
      retrieve_docs.each_value do |list|
        @all << list['title'].gsub(/\s+(.)/) {$1.upcase}
      end
    end

    def update_api_docs
      docs = JSON.parse(ENV['WATSON_API_DOCS'] || '{}')
      return if docs.empty?

      docs.each_pair do |key, value|
        @api_docs[key.to_sym] = value
      end
    end
  end
end


  # Options  = api_docs
  # Services = JSON.parse(ENV['VCAP_SERVICES'] || '{}')
  # DefaultParams = {:user=>'username', :password=>'password'}
  # AvailableAPIs = []