#!/usr/bin/env ruby -w
# frozen_string_literal: true
# encoding: UTF-8
#
# = ReportServlet_spec.rb -- The TaskJuggler III Project Management Software
#
# Copyright (c) 2026 Enno Richter <2536303+elohmeier@users.noreply.github.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#

require 'taskjuggler/Tj3Config'
require 'taskjuggler/daemon/ReportServlet'

class TaskJuggler

  describe ReportServlet do

    def response
      Class.new do
        attr_accessor :body, :status

        def initialize
          @headers = {}
        end

        def [](key)
          @headers[key]
        end

        def []=(key, value)
          @headers[key] = value
        end
      end.new
    end

    it 'generates a welcome page with projects when string literals are frozen' do
      broker = double('broker', :getProjectList => [ 'example' ],
                      :disconnect => nil)
      servlet = ReportServlet.allocate
      res = response
      servlet.instance_variable_set(:@res, res)
      allow(AppConfig).to receive(:appName).and_return('tj3webd')
      allow(servlet).to receive(:connectToBroker).and_return(broker)
      allow(servlet).to receive(:getProjectName).with('example').
        and_return('Example Project')

      servlet.send(:generateWelcomePage, '')

      res['content-type'].should eq('text/html')
      res.body.should match(/Example Project/)
    end

    it 'uses writable buffers while generating a report' do
      broker = double('broker', :getProject => [ 'project-uri', 'project-key' ],
                      :disconnect => nil)
      projectServer = double('project server',
                             :getReportServer => [ 'report-uri', 'report-key' ])
      reportServer = double('report server')
      allow(reportServer).to receive(:connect) do |_key, stdOut, stdErr,
                                                   _stdIn, _silent|
        stdOut.write('<html>Generated report</html>')
        stdErr.write('')
      end
      allow(reportServer).to receive(:generateReport).and_return(true)
      allow(reportServer).to receive(:disconnect)
      allow(reportServer).to receive(:terminate)
      allow(DRbObject).to receive(:new).
        and_return(projectServer, reportServer)

      servlet = ReportServlet.allocate
      res = response
      servlet.instance_variable_set(:@res, res)
      allow(servlet).to receive(:connectToBroker).and_return(broker)

      servlet.send(:generateReport, 'example', 'report', '')

      res['content-type'].should eq('text/html')
      res.body.should eq('<html>Generated report</html>')
    end

  end

end
