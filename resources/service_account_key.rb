# Copyright 2018 Google Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ----------------------------------------------------------------------------
#
#     ***     AUTO GENERATED CODE    ***    AUTO GENERATED CODE     ***
#
# ----------------------------------------------------------------------------
#
#     This file is automatically generated by Magic Modules and manual
#     changes will be clobbered when the file is regenerated.
#
#     Please read more about how to change this file in README.md and
#     CONTRIBUTING.md located at the root of this package.
#
# ----------------------------------------------------------------------------

# Add our google/ lib
$LOAD_PATH.unshift ::File.expand_path('../libraries', ::File.dirname(__FILE__))

require 'base64'
require 'chef/resource'
require 'google/hash_utils'
require 'google/iam/network/delete'
require 'google/iam/network/get'
require 'google/iam/network/post'
require 'google/iam/network/put'
require 'google/iam/property/boolean'
require 'google/iam/property/enum'
require 'google/iam/property/serviceaccount_name'
require 'google/iam/property/string'
require 'google/iam/property/time'

module Google
  module GIAM
    # A provider to manage Google Cloud IAM resources.
    class ServiceAccountKey < Chef::Resource
      resource_name :giam_service_account_key

      property :sak_label,
               String,
               coerce: ::Google::Iam::Property::String.coerce,
               name_property: true, desired_state: true
      property :private_key_type,
               equal_to: %w[TYPE_UNSPECIFIED TYPE_PKCS12_FILE TYPE_GOOGLE_CREDENTIALS_FILE],
               coerce: ::Google::Iam::Property::Enum.coerce, desired_state: true
      property :key_algorithm,
               equal_to: %w[KEY_ALG_UNSPECIFIED KEY_ALG_RSA_1024 KEY_ALG_RSA_2048],
               coerce: ::Google::Iam::Property::Enum.coerce, desired_state: true
      property :private_key_data,
               String, coerce: ::Google::Iam::Property::String.coerce, desired_state: true
      property :public_key_data,
               String, coerce: ::Google::Iam::Property::String.coerce, desired_state: true
      property :valid_after_time,
               Time, coerce: ::Google::Iam::Property::Time.coerce, desired_state: true
      property :valid_before_time,
               Time, coerce: ::Google::Iam::Property::Time.coerce, desired_state: true
      property :service_account,
               [String, ::Google::Iam::Data::ServiceAccountNameRef],
               coerce: ::Google::Iam::Property::ServiceAccountNameRef.coerce, desired_state: true
      property :path, String, coerce: ::Google::Iam::Property::String.coerce, desired_state: true
      property :key_id, String, coerce: ::Google::Iam::Property::String.coerce, desired_state: true
      property :fail_if_mismatch,
               kind_of: [TrueClass, FalseClass],
               coerce: ::Google::Iam::Property::Boolean.coerce, desired_state: true

      property :credential, String, desired_state: false, required: true
      property :project, String, desired_state: false, required: true

      action :create do
        (key_file_exists, key_id) = get_key_id(@new_resource)
        unless key_id.nil?
          # If key_id, check keys existence.
          req = ::Google::Iam::Network::Get.new(
            self_link(service_account: @new_resource.service_account,
                      project: @new_resource.project, key_id: key_id),
            fetch_auth(@new_resource)
          )
          fetch = return_if_object req.send
          unless fetch.nil?
            fetch.merge!('name' => name, 'keyId' => key_id,
                          # TODO(nelsonjr): Add support to PKCS12 key files
                          'privateKeyType' => 'TYPE_GOOGLE_CREDENTIALS_FILE')
          end
        end
        if fetch.nil?
          converge_by "Creating giam_service_account_key[#{new_resource.name}]" do
            # TODO(nelsonjr): Show a list of variables to create
            # TODO(nelsonjr): Determine how to print green like update converge
            puts # making a newline until we find a better way TODO: find!
            compute_changes.each { |log| puts "    - #{log.strip}\n" }
            @created = true
            create_req = ::Google::Iam::Network::Post.new(collection(@new_resource),
                                                          fetch_auth(@new_resource),
                                                          'application/json',
                                                          resource_to_request)
            @fetched = return_if_object create_req.send
            if @fetched['privateKeyData'] && @new_resource.path
              # Write to file if a file name is provided.
              json = Base64.decode64(@fetched['privateKeyData'])
              ::File.open(@new_resource.path, 'w') { |file| file.write(json) }
            end
          end
        else
          @current_resource = @new_resource.clone
          @current_resource.sak_label = ::Google::Iam::Property::String.api_parse(fetch['name'])
          @current_resource.private_key_type =
            ::Google::Iam::Property::Enum.api_parse(fetch['privateKeyType'])
          @current_resource.key_algorithm =
            ::Google::Iam::Property::Enum.api_parse(fetch['keyAlgorithm'])
          @current_resource.private_key_data =
            ::Google::Iam::Property::String.api_parse(fetch['privateKeyData'])
          @current_resource.public_key_data =
            ::Google::Iam::Property::String.api_parse(fetch['publicKeyData'])
          @current_resource.valid_after_time =
            ::Google::Iam::Property::Time.api_parse(fetch['validAfterTime'])
          @current_resource.valid_before_time =
            ::Google::Iam::Property::Time.api_parse(fetch['validBeforeTime'])

          update
        end
      end

      action :delete do
        fetch = fetch_resource(@new_resource, self_link(@new_resource))
        unless fetch.nil?
          converge_by "Deleting giam_service_account_key[#{new_resource.name}]" do
            (_, key_id) = get_key_id(@new_resource)
            delete_req = ::Google::Iam::Network::Delete.new(
              self_link(service_account: @new_resource.service_account,
                        project: @new_resource.project, key_id: key_id),
              fetch_auth(@new_resource)
            )
            return_if_object delete_req.send
          end
        end
      end

      # TODO(nelsonjr): Add actions :manage and :modify

      private

      action_class do
        def resource_to_request
          request = {
            privateKeyType: new_resource.private_key_type,
            keyAlgorithm: new_resource.key_algorithm
          }.reject { |_, v| v.nil? }
          request.to_json
        end

        def update
          converge_if_changed do |_vars|
            # TODO(nelsonjr): Determine how to print indented like upd converge
            # TODO(nelsonjr): Check w/ Chef... can we print this in red?
            puts # making a newline until we find a better way TODO: find!
            compute_changes.each { |log| puts "    - #{log.strip}\n" }
            @created = true
            create_req = ::Google::Iam::Network::Post.new(collection(@new_resource),
                                                          fetch_auth(@new_resource),
                                                          'application/json',
                                                          resource_to_request)
            @fetched = return_if_object create_req.send
            if @fetched['privateKeyData'] && @new_resource.path
              # Write to file if a file name is provided.
              json = Base64.decode64(@fetched['privateKeyData'])
              ::File.open(@new_resource.path, 'w') { |file| file.write(json) }
            end
          end
        end

        def self.fetch_export(resource, type, id, property)
          return if id.nil?
          resource.resources("#{type}[#{id}]").exports[property]
        end

        def self.resource_to_hash(resource)
          {
            project: resource.project,
            name: resource.sak_label,
            private_key_type: resource.private_key_type,
            key_algorithm: resource.key_algorithm,
            private_key_data: resource.private_key_data,
            public_key_data: resource.public_key_data,
            valid_after_time: resource.valid_after_time,
            valid_before_time: resource.valid_before_time,
            service_account: resource.service_account,
            path: resource.path,
            key_id: resource.key_id,
            fail_if_mismatch: resource.fail_if_mismatch
          }.reject { |_, v| v.nil? }
        end

        # Copied from Chef > Provider > #converge_if_changed
        def compute_changes
          properties = @new_resource.class.state_properties.map(&:name)
          properties = properties.map(&:to_sym)
          if current_resource
            compute_changes_for_existing_resource properties
          else
            compute_changes_for_new_resource properties
          end
        end

        # Collect the list of modified properties
        def compute_changes_for_existing_resource(properties)
          specified_properties = properties.select do |property|
            @new_resource.property_is_set?(property)
          end
          modified = specified_properties.reject do |p|
            @new_resource.send(p) == current_resource.send(p)
          end

          generate_pretty_green_text(modified)
        end

        def generate_pretty_green_text(modified)
          property_size = modified.map(&:size).max
          modified.map! do |p|
            properties_str = if @new_resource.sensitive
                               '(suppressed sensitive property)'
                             else
                               [
                                 @new_resource.send(p).inspect,
                                 "(was #{current_resource.send(p).inspect})"
                               ].join(' ')
                             end
            "  set #{p.to_s.ljust(property_size)} to #{properties_str}"
          end
        end

        # Write down any properties we are setting.
        def compute_changes_for_new_resource(properties)
          property_size = properties.map(&:size).max
          properties.map do |property|
            default = ' (default value)' \
              unless @new_resource.property_is_set?(property)
            next if @new_resource.send(property).nil?
            properties_str = if @new_resource.sensitive
                               '(suppressed sensitive property)'
                             else
                               @new_resource.send(property).inspect
                             end
            ["  set #{property.to_s.ljust(property_size)}",
             "to #{properties_str}#{default}"].join(' ')
          end.compact
        end

        def fetch_auth(resource)
          self.class.fetch_auth(resource)
        end

        def self.fetch_auth(resource)
          resource.resources("gauth_credential[#{resource.credential}]")
                  .authorization
        end

        def fetch_resource(resource, self_link)
          self.class.fetch_resource(resource, self_link)
        end

        def debug(message)
          Chef::Log.debug(message)
        end

        def self.collection(data)
          URI.join(
            'https://iam.googleapis.com/v1/',
            expand_variables(
              'projects/{{project}}/serviceAccounts/{{service_account}}/keys',
              data
            )
          )
        end

        def collection(data)
          self.class.collection(data)
        end

        def self.self_link(data)
          URI.join(
            'https://iam.googleapis.com/v1/',
            expand_variables(
              ['projects/{{project}}/serviceAccounts/{{service_account}}',
               'keys/{{key_id}}'].join('/'),
              data
            )
          )
        end

        def self_link(data)
          self.class.self_link(data)
        end

        def self.return_if_object(response)
          raise "Bad response: #{response.body}" \
            if response.is_a?(Net::HTTPBadRequest)
          raise "Bad response: #{response}" \
            unless response.is_a?(Net::HTTPResponse)
          return if response.is_a?(Net::HTTPNotFound)
          return if response.is_a?(Net::HTTPNoContent)
          result = decode_response(response)
          raise_if_errors result, %w[error errors], 'message'
          raise "Bad response: #{response}" unless response.is_a?(Net::HTTPOK)
          result
        end

        def return_if_object(response)
          self.class.return_if_object(response)
        end

        def self.extract_variables(template)
          template.scan(/{{[^}]*}}/).map { |v| v.gsub(/{{([^}]*)}}/, '\1') }
                  .map(&:to_sym)
        end

        def self.expand_variables(template, var_data, extra_data = {})
          data = if var_data.class <= Hash
                   var_data.merge(extra_data)
                 else
                   resource_to_hash(var_data).merge(extra_data)
                 end
          extract_variables(template).each do |v|
            unless data.key?(v)
              raise "Missing variable :#{v} in #{data} on #{caller.join("\n")}}"
            end
            template.gsub!(/{{#{v}}}/, CGI.escape(data[v].to_s))
          end
          template
        end

        # A module to hold instance information about the service account key file,
        # used during creation/update of the key between GCP <=> key file.
        def get_key_id(resource)
          key_file_exists =
            (::File.exist?(resource.path)) || false
          if key_file_exists
            # If key file exists, fetch the key ID from it.
            file = ::File.open(resource.path)
            [key_file_exists, ::JSON.parse(file.read)['private_key_id']]
          elsif !resource.key_id.nil?
            [key_file_exists, resource.key_id]
          end
        end

        def self.decode_response(response)
          response = ::JSON.parse(response.body)
          if response.key? 'privateKeyData'
            response.merge!(::JSON.parse(::Base64.decode64(response['privateKeyData'])))
          end
          response
        end

        def decode_response(response)
          self.class.decode_response(response)
        end

        def self.fetch_resource(resource, self_link)
          get_request = ::Google::Iam::Network::Get.new(
            self_link, fetch_auth(resource)
          )
          return_if_object get_request.send
        end

        def self.raise_if_errors(response, err_path, msg_field)
          errors = ::Google::HashUtils.navigate(response, err_path)
          raise_error(errors, msg_field) unless errors.nil?
        end

        def self.raise_error(errors, msg_field)
          raise IOError, ['Operation failed:',
                          errors.map { |e| e[msg_field] }.join(', ')].join(' ')
        end
      end
    end
  end
end
