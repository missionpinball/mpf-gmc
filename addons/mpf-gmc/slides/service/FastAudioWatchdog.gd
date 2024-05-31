# Copyright 2023 Paradigm Tilt
extends Node2D

func _ready():
  var response = []
  OS.execute("/Users/anthony/git/paradigm-build/files/fast_audio_comm.sh", ["AS:1F"], true, response)
  var result = response[0].split("\r")
  print("Got a response of %d lines: %s" % [result.size(), String(result)])
  for line in result:
    if line and line.substr(0,3) != "WD:":
      print("The line we care about! <<<%s>>>" % line)
