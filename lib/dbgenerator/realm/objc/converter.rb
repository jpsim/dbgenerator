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

module DBGenerator
  module Realm
    module ObjC
      module Converter

        TYPES = {
            :integer_16 => 'int',
            :integer_32 => 'long',
            :integer_64 => 'long long',
            :decimal => 'double',
            :double => 'double',
            :float => 'float',
            :string => 'NSString *',
            :boolean => 'BOOL',
            :date => 'NSDate *',
            :binary => 'NSData *'
        }

        DEFAULTS = {
            :integer_16 => '@(0)',
            :integer_32 => '@(0)',
            :integer_64 => '@(0)',
            :decimal => '@(0.0)',
            :double => '@(0.0)',
            :float => '@(0.0)',
            :string => '@""',
            :boolean => '@(NO)',
            :date => '[NSDate date]',
            :binary => '[NSData new]'
        }

        def is_number_type?(type)
          [:integer_16, :integer_32, :integer_64, :decimal, :double, :float].include?(type)
        end

        def convert_type(type, use_nsnumber = false)
          use_nsnumber && is_number_type?(type) ? 'NSNumber *' : TYPES[type]
        end

        def convert_default(type)
          DEFAULTS[type]
        end

      end
    end
  end
end
