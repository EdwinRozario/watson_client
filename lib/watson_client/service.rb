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

    def fetch_all_services
      @all = []

      # yet to be written
      retrieve_doc(doc_urls).each_value do |list|
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