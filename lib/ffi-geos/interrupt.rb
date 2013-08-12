
module Geos
  module Interrupt
    class << self
      if FFIGeos.respond_to?(:GEOS_interruptRegisterCallback)
        # Check for the availability of the GEOS interruption API. The
        # interruption API was added in GEOS 3.4.0.
        def available?
          true
        end

        # Registers an interrupt method or block that may be called during
        # certain operations such as Geos::Geometry#buffer. During these
        # blocks you can interrupt the current operation using
        # Geos.request_interrupt and cancel that interrupt request using
        # Geos.clear_interrupt.
        #
        # The return value for Geos.register_interrupt is a reference to the
        # previously registered callback, allowing you to chain interrupt
        # calls together by calling #call on the previously registered callback.
        #
        # HUGE NOTE CONCERNING INTERRUPTS: be careful when using interrupt
        # blocks and how they reference other ruby objects. The ruby garbage
        # collector may not play nicely with GEOS and objects may get cleaned
        # up in unexpected ways while interrupts are firing.
        def register(method_or_block = nil, &block)
          if method_or_block.nil? && !block_given?
            raise ArgumentError.new("Expected either a method or a block for Geos.register_interrupt")
          elsif !method_or_block.nil? && block_given?
            raise ArgumentError.new("Cannot use both a method and a block for Geos.register_interrupt")
          else
            retval = @current_interrupt_callback

            @current_interrupt_callback = if method_or_block
              FFIGeos.GEOS_interruptRegisterCallback(method_or_block)
              method_or_block
            elsif block_given?
              FFIGeos.GEOS_interruptRegisterCallback(&block)
              block
            end

            retval
          end
        end

        # Interrupt the current operation. This method should generally be
        # called from within a callback registered with Geos.register_interrupt
        # but can be called at any time to interrupt the next interruptable
        # operation.
        def request
          FFIGeos.GEOS_interruptRequest
        end

        # Cancel a request to interrupt the current operation. This method
        # should be called from within a callback registered with
        # Geos.register_interrupt but can be called at any time all the same.
        def cancel
          FFIGeos.GEOS_interruptCancel
        end

        def clear
          FFIGeos.GEOS_interruptRegisterCallback(nil)
          @current_interrupt_callback = nil
        end
      else
        def available?
          false
        end
      end
    end
  end
end

