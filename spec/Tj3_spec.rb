#!/usr/bin/env ruby -w
# frozen_string_literal: true
# encoding: UTF-8
#
# = Tj3_spec.rb -- The TaskJuggler III Project Management Software
#
# Copyright (c) 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014
#               by Chris Schlaeger <cs@taskjuggler.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#

require 'rubygems'
require 'tmpdir'
require 'taskjuggler/StdIoWrapper'
require 'taskjuggler/apps/Tj3'

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
end

class TaskJuggler

  describe Tj3 do

    include StdIoWrapper

    def generateSelectedReport(option, selector)
      Dir.mktmpdir('tj3-output-dir-') do |dir|
        outputDir = File.join(dir, 'output')
        projectFile = File.join(dir, 'project.tjp')
        workDir = File.join(dir, 'work')
        Dir.mkdir(outputDir)
        Dir.mkdir(workDir)
        File.write(projectFile, <<~'TJP')
          project "Foo" 2011-03-14 +1d {
            timezone "UTC"
          }
          task "Foo"
          taskreport overview "overview" {
            formats html
          }
        TJP

        result = nil
        Dir.chdir(workDir) do
          result = stdIoWrapper do
            Tj3.new.main([ '--silent', '--output-dir', outputDir,
                           option, selector, projectFile ])
          end
        end

        result.stdErr.should eq('')
        result.returnValue.should eq(0)
        File.file?(File.join(outputDir, 'overview.html')).should be(true)
        Dir.children(workDir).should be_empty
      end
    end

    it 'should schedule a project' do
      prj = 'project "Foo" 2011-03-14 +1d task "Foo"'
      res = stdIoWrapper(prj) do
        Tj3.new.main(%w( --silent --no-reports . ))
      end
      res.stdErr.should == ''
      res.returnValue.should == 0
    end

    it 'writes --report output to the output directory' do
      generateSelectedReport('--report', 'overview')
    end

    it 'writes --reports output to the output directory' do
      generateSelectedReport('--reports', '^overview$')
    end

  end

end
