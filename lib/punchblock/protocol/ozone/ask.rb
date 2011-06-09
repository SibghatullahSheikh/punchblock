module Punchblock
  module Protocol
    module Ozone
      class Ask < Command
        register :ask, :ask

        ##
        # Create an ask message
        #
        # @param [String] prompt to ask the caller
        # @param [String] choices to ask the user
        # @param [Hash] options for asking/prompting a specific call
        # @option options [Symbol, Optional] :mode by which to accept input. Can be :speech, :dtmf or :any
        # @option options [Integer, Optional] :response_timeout to wait for user input
        # @option options [String, Optional] :recognizer to use for speech recognition
        # @option options [String, Optional] :voice to use for speech synthesis
        # @option options [String, Optional] :terminator by which to signal the end of input
        # @option options [Float, Optional] :min_confidence with which to consider a response acceptable
        # @option options [String or Nokogiri::XML, Optional] :grammar to use for speech recognition (ie - application/grammar+voxeo or application/grammar+grxml)
        #
        # @return [Ozone::Message] a formatted Ozone ask message
        #
        # @example
        #    ask 'Please enter your postal code.',
        #        '[5 DIGITS]',
        #        :timeout => 30,
        #        :recognizer => 'es-es',
        #        :voice => 'simon'
        #
        #    returns:
        #      <ask xmlns="urn:xmpp:ozone:ask:1" timeout="30" recognizer="es-es">
        #        <prompt voice='simon'>Please enter your postal code.</prompt>
        #        <choices content-type="application/grammar+voxeo">[5 DIGITS]</choices>
        #      </ask>
        def self.new(prompt = '', options = {})
          super().tap do |new_node|
            voice = options.delete :voice
            new_node.choices = {:content_type => options.delete(:grammar), :value => options.delete(:choices)}

            options.each_pair do |k,v|
              new_node.send :"#{k}=", v
            end

            # Nokogiri::XML::Builder.with msg.instance_variable_get(:@xml) do |xml|
            #   prompt_opts = {:voice => voice} if voice
            #   xml.prompt prompt_opts do
            #     xml.text prompt
            #   end

          end
        end

        def bargein
          self[:bargein] == "true"
        end

        def bargein=(bargein)
          self[:bargein] = bargein.to_s
        end

        def min_confidence
          self['min-confidence'].to_f
        end

        def min_confidence=(min_confidence)
          self['min-confidence'] = min_confidence
        end

        def mode
          self[:mode].to_sym
        end

        def mode=(mode)
          self[:mode] = mode
        end

        def recognizer
          self[:recognizer]
        end

        def recognizer=(recognizer)
          self[:recognizer] = recognizer
        end

        def terminator
          self[:terminator]
        end

        def terminator=(terminator)
          self[:terminator] = terminator
        end

        def response_timeout
          self[:timeout].to_i
        end

        def response_timeout=(rt)
          self[:timeout] = rt
        end

        def choices
          Choices.new find_first('ns:choices', :ns => self.class.registered_ns)
        end

        def choices=(choices)
          remove_children :choices
          self << Choices.new(choices)
        end

        class Choices < OzoneNode
          def self.new(value, content_type = 'application/grammar+voxeo')
            # Default is the Voxeo Simple Grammar, unless specified

            super(:choices).tap do |new_node|
              case value
              when Nokogiri::XML::Node
                new_node.inherit value
              when Hash
                new_node.content_type = value[:content_type]
                new_node.value = value[:value]
              else
                new_node.content_type = content_type
                new_node.value = value
              end
            end
          end

          # The Header's name
          # @return [Symbol]
          def content_type
            read_attr 'content-type'
          end

          # Set the Header's name
          # @param [Symbol] name the new name for the header
          def content_type=(content_type)
            write_attr 'content-type', content_type
          end

          # The Header's value
          # @return [String]
          def value
            content
          end

          # Set the Header's value
          # @param [String] value the new value for the header
          def value=(value)
            Nokogiri::XML::Builder.with(self) do |xml|
              if content_type == 'application/grammar+grxml'
                xml.cdata value
              else
                xml.text value
              end
            end
          end

          # Compare two Header objects by name, and value
          # @param [Header] o the Header object to compare against
          # @return [true, false]
          def eql?(o, *fields)
            super o, *(fields + [:content_type])
          end
        end
      end # Ask
    end # Ozone
  end # Protocol
end # Punchblock
