class Module

  # Document methods that MUST be overridden by child classes.
  def abstract(method_name)
    define_method(method_name) do
      fail NotImplementedError
    end
  end

  # Document methods that CAN or SHOULD be overridden by child classes.
  def overridable(method_name)
    method_name
  end

  # Document methods that are overriding a parent class.
  def override(method_name)
    method_name
  end

  # Delegate a set of methods to another object.
  # This is meant to be a simpler version of Rails' ActiveSupport implementation.
  def delegate(*methods, to: nil)
    fail ArgumentError, "Must specify target of `delegate` using `to` keyword argument." if to.nil?
    to = to.to_sym
    to = "self.#{to}" unless to.start_with?("@")
    methods.each do |method|
      define_method(method) do |*args|
        receiver = instance_eval(to)
        receiver.__send__(method, *args)
      end
    end
  end

end
