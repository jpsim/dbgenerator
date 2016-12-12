=begin
Copyright 2016 - Niji

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=end

require 'nokogiri'
require 'set'
require File.expand_path('relationship', File.dirname(__FILE__))
require File.expand_path('attribute', File.dirname(__FILE__))

module DBGenerator
  module XCDataModel
    module Parser
      class Entity

        attr_accessor :name, :parent, :abstract, :attributes, :relationships, :identity_attribute, :comment
        alias_method :abstract?, :abstract

        def initialize(entity_xml)
          @name = entity_xml.xpath('@name').to_s
          @parent = entity_xml.xpath('@parentEntity').to_s
          @abstract = entity_xml.xpath('@isAbstract').to_s == 'YES' ? true : false
          @clean = false
          @identity_attribute = entity_xml.xpath(USERINFO_VALUE%['identityAttribute']).to_s
          @comment = entity_xml.xpath(USERINFO_VALUE%['comment']).to_s
          @attributes = Hash.new
          @relationships = Hash.new
          load_entity(entity_xml)
        end

        def to_s
          str = "\nEntity => #{@name}\n"
          @attributes.each do |_, attribute|
            str += attribute.to_s
          end
          @relationships.each do |_, relationship|
            str += relationship.to_s
          end
          str
        end

        def used_as_list_by_other?(entities)
          entities.each do |_, entity|
            entity.relationships.each do |_, relationship|
              return true if relationship.inverse_type == @name and relationship.type == :to_many
            end
          end
          false
        end

        def has_list_attributes?(inverse = false)
          @relationships.each do |_, relationship|
            return true if relationship.type == :to_many and (!inverse ? !relationship.inverse? : true)
          end
          false
        end

        def has_no_inverse_relationship?
          @relationships.each do |_, relationship|
            return true unless relationship.inverse?
          end
          false
        end

        def has_ignored?
          @attributes.each do |_, attribute|
            return true if attribute.realm_ignored?
          end
          @relationships.each do |_, relationship|
            return true if relationship.realm_ignored?
          end
          false
        end

        def has_primary_key?
          !@identity_attribute.empty?
        end

        def has_required?
          @attributes.each do |_, attribute|
            return true if is_required?(attribute)
          end
          false
        end

        def is_required?(attribute)
          unless attribute.optional?
            return true unless self.has_primary_key?
            return true if self.has_primary_key? && !attribute.name.eql?(identity_attribute)
          end
          false
        end

        def has_default_value?(attribute = @identity_attribute)
          attribute.name != @identity_attribute
        end

        def has_indexed_attributes?
          @attributes.each do |_, attribute|
            return true if attribute.indexed?
          end
          false
        end

        def has_json_key_path?
          @attributes.each do |_, attribute|
            return true unless attribute.json_key_path.empty?
          end
          @relationships.each do |_, relationship|
            return true if !relationship.inverse? and !relationship.json_key_path.empty?
          end
          false
        end

        def has_enum_attributes?
          @attributes.each do |_, attribute|
            return true unless attribute.enum_type.empty?
          end
          false
        end

        def transformers
          transformers = Set.new
          @attributes.each do |_, attribute|
            transformers.add attribute.transformer unless attribute.transformer.empty?
          end
          transformers
        end

        def has_custom_transformers?
          @attributes.each do |_, attribute|
            return true unless attribute.transformer.empty?
          end
          false
        end

        def need_transformer?
          has_enum_attributes? || has_bool_attributes? || has_custom_transformers? || has_date_attribute?
        end

        def has_bool_attributes?
          has_bool_attributes = false
          @attributes.each do |_, attribute|
            has_bool_attributes = true if attribute.type == :boolean
          end
          has_bool_attributes
        end

        def has_number_attributes?
          has_number_attributes = false
          @attributes.each do |_, attribute|
            if attribute.enum_type.empty?
              case attribute.type
                when :integer_16 then
                  has_number_attributes = true
                when :integer_32 then
                  has_number_attributes = true
                when :integer_64 then
                  has_number_attributes = true
                when :decimal then
                  has_number_attributes = true
                when :double then
                  has_number_attributes = true
                when :float then
                  has_number_attributes = true
                else
                  has_number_attributes = false
              end
              break if has_number_attributes
            end
          end
          has_number_attributes
        end

        def has_date_attribute?
          @attributes.each do |_, attribute|
            return true if attribute.type == :date
          end
          false
        end

        def has_list_relationship?
          @relationships.each do |_, relationship|
            return true unless relationship.destination.empty?
          end
          false
        end

        def has_only_inverse?
          nb_inverses = 0
          @relationships.each do |_, relationship|
            nb_inverses+=1 if relationship.inverse?
          end
          nb_inverses==@relationships.size
        end

        private ################################################################

        def load_entity(entity_xml)
          load_attributes(entity_xml)
          load_relationships(entity_xml)
        end

        def load_attributes(entity_xml)
          entity_xml.xpath('attribute').each do |node|
            attribute = Attribute.new(node, @name)
            if attribute.type != 'Transformable'
              @attributes[attribute.name] = attribute
            end
          end
        end

        def load_relationships(entity_xml)
          entity_xml.xpath('relationship').each do |node|
            relationship = Relationship.new(node, @name)
            @relationships[relationship.name] = relationship
          end
        end
      end

    end
  end
end
