# Custom exceptions for AggregatorX module

struct IncompleteSystemException <: Exception
end

struct DuplicateIdException <: Exception
end

struct MissingIdException <: Exception
end