# Wrapper class for GMC singletons that require references
# to the MPF global autoload. This class accepts the global
# as an argument so refs can be internalized.

extends LoggingNode
class_name GMCNode

var mpf: Node

func _init(mpf_gmc) -> void:
    self.mpf = mpf_gmc
