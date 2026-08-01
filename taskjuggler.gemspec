# -*- coding: utf-8 -*-
#
# = taskjuggler.gemspec -- The TaskJuggler III Project Management Software
#
# Copyright (c) 2006, 2007, 2008, 2009, 2010, 2011, 2025
#               by Chris Schlaeger <chris@linux.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This gemspec file will be used to package the taskjuggler gem. Before you
# use it, the manual and other generated files must have been created!

lib = File.expand_path('../lib', __FILE__)
$:.unshift lib unless $:.include?(lib)

# Keep gem metadata loadable before runtime dependencies have been installed.
require_relative 'lib/taskjuggler/version'
PROJECT_VERSION = VERSION
PROJECT_NAME = 'TaskJuggler'

filesIn = lambda do |directory|
  files = (`git ls-files -- #{directory} 2>/dev/null`).split("\n")
  files.empty? ? Dir.glob("#{directory}/**/*").select { |f| File.file?(f) } : files
end

GEM_SPEC = Gem::Specification.new { |s|
  s.name = 'taskjuggler'
  s.version = PROJECT_VERSION
  s.homepage = 'http://www.taskjuggler.org'
  s.author = 'Chris Schlaeger'
  s.email = 'chris@linux.com'
  s.summary = 'A Project Management Software'
  s.description = <<'EOT'
TaskJuggler is a modern and powerful, Free and Open Source Software project
management tool. It's new approach to project planning and tracking is more
flexible and superior to the commonly used Gantt chart editing tools.

TaskJuggler is project management software for serious project managers. It
covers the complete spectrum of project management tasks from the first idea
to the completion of the project. It assists you during project scoping,
resource assignment, cost and revenue planning, risk and communication
management.
EOT
  s.license = 'GPL-2.0-only'
  s.require_path = 'lib'
  s.files = filesIn.call('lib') +
            filesIn.call('data') +
            filesIn.call('manual') +
            filesIn.call('examples') +
            filesIn.call('tasks') +
            %w( .gemtest taskjuggler.gemspec Rakefile ) +
            # Generated files, not contained in Git repository.
            Dir.glob('manual/html/**/*') + Dir.glob('man/*.1')
  s.bindir = 'bin'
  s.executables = filesIn.call('bin').
                  map { |fn| File.basename(fn) }
  s.test_files = filesIn.call('test') + filesIn.call('spec')

  s.extra_rdoc_files = %w( README.rdoc COPYING )

  s.add_dependency('base64', '>= 0.2.0')
  s.add_dependency('drb', '>= 2.1.0')
  s.add_dependency('mail', '~> 2.7', '>= 2.7.1')
  s.add_dependency('webrick', '~> 1.9', '>= 1.9.1')
  s.add_runtime_dependency('term-ansicolor', '~> 1.7', '>= 1.7.1')
  s.add_development_dependency('rake', '~> 13.0')
  s.add_development_dependency('rspec', '~> 3.13')
  s.add_development_dependency('test-unit', '~> 3.7')
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version  = '>= 3.2.0'
}
