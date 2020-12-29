class Module

  # Document methods that NEED to be overridden by child classes.
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

end
