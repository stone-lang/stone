Literate Ruby
=============

This document will document the Literate Ruby gem, using its own dog food.
This document itself will be sent through the process.

~~~ ruby
module LiterateRuby
  def require(module_name)
    return true if already_required?(module_name)
    existing_module = find_module(module_name)
    if existing_module
  end

  private def already_required?(module_name)
    # TODO
  end

  private def find_module(module_name)
    # TODO
  end
end
~~~

