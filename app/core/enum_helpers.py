"""
Helper functions for handling enums with case insensitivity
"""
from enum import Enum
from typing import Any, Type, TypeVar, Optional, Dict, List

E = TypeVar('E', bound=Enum)

def case_insensitive_enum_parser(value: Any, enum_class: Type[E]) -> Optional[E]:
    """
    Convert a string value to an enum member in a case-insensitive way.
    
    Args:
        value: The value to convert (usually a string)
        enum_class: The enum class to convert to
        
    Returns:
        The matching enum member, or None if no match is found
    """
    if value is None:
        return None
        
    # Handle enum objects directly
    if isinstance(value, enum_class):
        return value
        
    # Convert value to string and uppercase for comparison
    value_str = str(value).upper()
    
    # Try to match by enum value (case insensitive)
    for enum_member in enum_class:
        if str(enum_member.value).upper() == value_str:
            return enum_member
    
    # Try to match by enum name (case insensitive)
    try:
        return enum_class[value_str]
    except (KeyError, ValueError):
        pass
        
    # No match found
    return None
    
def safely_get_enum(value: Any, enum_class: Type[E], default: Optional[E] = None) -> Optional[E]:
    """
    Safely convert a value to an enum member, with case insensitivity.
    Returns the default if no match is found.
    
    Args:
        value: The value to convert
        enum_class: The enum class to convert to
        default: The default value to return if no match is found
        
    Returns:
        The matching enum member, or default if no match is found
    """
    result = case_insensitive_enum_parser(value, enum_class)
    return result if result is not None else default

def get_all_enum_values(enum_class: Type[E]) -> List[str]:
    """
    Get all possible values of an enum class.
    
    Args:
        enum_class: The enum class
        
    Returns:
        List of all enum values as strings
    """
    return [str(e.value) for e in enum_class] 