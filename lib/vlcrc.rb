#!/usr/bin/env ruby

require 'socket'
require 'timeout'

base = File.dirname(__FILE__)

require File.join base, 'vlcrc', 'core'
require File.join base, 'vlcrc', 'version'
