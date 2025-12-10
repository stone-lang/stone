require "stone/type/base"
require "stone/type/Bool"
require "stone/type/Int"
require "stone/type/String"
require "stone/type/type"

# Set up property type mappings now that all types are loaded
Stone::Type::Int::PROPERTY_TYPES["positive?"] = Stone::Type::Bool
Stone::Type::Int::PROPERTY_TYPES["negative?"] = Stone::Type::Bool
Stone::Type::Int::PROPERTY_TYPES["zero?"] = Stone::Type::Bool
Stone::Type::Int::PROPERTY_TYPES["as_String"] = Stone::Type::String

Stone::Type::Bool::PROPERTY_TYPES["not"] = Stone::Type::Bool
Stone::Type::Bool::PROPERTY_TYPES["as_String"] = Stone::Type::String

Stone::Type::String::PROPERTY_TYPES["byte_count"] = Stone::Type::Int
Stone::Type::String::PROPERTY_TYPES["empty?"] = Stone::Type::Bool
Stone::Type::String::PROPERTY_TYPES["as_String"] = Stone::Type::String

Stone::Type::Type::PROPERTY_TYPES["as_String"] = Stone::Type::String
