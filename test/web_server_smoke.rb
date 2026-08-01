#!/usr/bin/env ruby -w
# frozen_string_literal: true
# encoding: UTF-8
#
# = web_server_smoke.rb -- The TaskJuggler III Project Management Software
#
# Copyright (c) 2026 Enno Richter <2536303+elohmeier@users.noreply.github.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#

require 'net/http'
require 'rbconfig'
require 'fileutils'
require 'socket'
require 'timeout'
require 'tmpdir'

def freePort
  server = TCPServer.new('127.0.0.1', 0)
  port = server.addr[1]
  server.close
  port
end

def waitForPort(port)
  Timeout.timeout(15) do
    loop do
      socket = TCPSocket.new('127.0.0.1', port)
      socket.close
      return
    rescue Errno::ECONNREFUSED
      sleep 0.1
    end
  end
end

def stopProcess(pid)
  return unless pid

  begin
    Process.kill('TERM', pid)
  rescue Errno::ESRCH
  end

  begin
    Timeout.timeout(5) { Process.wait(pid) }
  rescue Errno::ECHILD
  rescue Timeout::Error
    begin
      Process.kill('KILL', pid)
      Process.wait(pid)
    rescue Errno::ESRCH, Errno::ECHILD
    end
  end
end

sourceDir = File.expand_path('..', __dir__)
sourceProjectFile = File.join(sourceDir,
                              'test/TestSuite/Syntax/Correct/textreport.tjp')
daemonPort = freePort
webPort = freePort

Dir.mktmpdir('taskjuggler-web-smoke-') do |runDir|
  configFile = File.join(runDir, 'taskjuggler.rc')
  daemonLog = File.join(runDir, 'daemon.log')
  projectFile = File.join(runDir, 'textreport.tjp')
  webLog = File.join(runDir, 'web.log')
  File.write(configFile, "_global:\n  authKey: ruby-compatibility-smoke\n")
  FileUtils.cp(sourceProjectFile, projectFile)

  daemonPid = nil
  webPid = nil
  begin
    daemonPid = Process.spawn(RbConfig.ruby, "-I#{sourceDir}/lib",
                              File.join(sourceDir, 'lib/tj3d.rb'),
                              '--silent', '--no-color', '--dont-daemonize',
                              '--config', configFile,
                              '--port', daemonPort.to_s,
                              projectFile,
                              :chdir => runDir,
                              :out => daemonLog, :err => [ :child, :out ])
    waitForPort(daemonPort)

    webPid = Process.spawn(RbConfig.ruby, "-I#{sourceDir}/lib",
                           File.join(sourceDir, 'lib/tj3webd.rb'),
                           '--silent', '--no-color', '--dont-daemonize',
                           '--config', configFile,
                           '--port', daemonPort.to_s,
                           '--webserver-port', webPort.to_s,
                           :chdir => runDir,
                           :out => webLog, :err => [ :child, :out ])
    waitForPort(webPort)

    base = URI("http://127.0.0.1:#{webPort}")
    welcome = Net::HTTP.get_response(base + '/taskjuggler')
    unless welcome.code == '200'
      raise "Welcome page returned HTTP #{welcome.code}: #{welcome.body}"
    end

    projectPath = welcome.body[/href="([^"]*project=[^"]*)"/, 1]
    raise 'Welcome page has no project link' unless projectPath

    projectPage = Net::HTTP.get_response(base + projectPath.gsub('&amp;', '&'))
    unless projectPage.code == '200'
      raise "Project page returned HTTP #{projectPage.code}: #{projectPage.body}"
    end

    reportPath = projectPage.body[/href="([^"]*report=[^"]*)"/, 1]
    raise 'Project page has no report link' unless reportPath

    reportPage = Net::HTTP.get_response(base + reportPath.gsub('&amp;', '&'))
    unless reportPage.code == '200' && reportPage.body.include?('<html')
      raise "Report page returned invalid HTML: HTTP #{reportPage.code}"
    end

    puts "Web server smoke test passed (#{reportPage.body.bytesize} bytes)"
  rescue
    warn File.read(daemonLog) if File.exist?(daemonLog)
    warn File.read(webLog) if File.exist?(webLog)
    raise
  ensure
    stopProcess(webPid)
    stopProcess(daemonPid)
  end
end
