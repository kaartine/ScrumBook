# Copyright (C) 2011 by Jukka Kaartinen

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'yaml'


class ScrumBController

  def initialize( gui )
    @project = Project.create
    @gui = gui
  end

  def startApp
    fileName = nil
    ARGV.each do|a|
      if File.exists?(a)
        fileName = a
      else
        title = "Error opening file"
        text = "File \"#{a}\" doesn't exist!"
        @gui.openInformationDialog(title, text)
      end
    end

    loadProject(fileName) unless fileName.nil?

    @gui.startMainLoop
  end

  def loadProject(fileName)
    logger "loadProject", 4
    if !File.exist?(fileName)
      return
    end

    file = File.new fileName, 'r'
    serial = file.read
    file.close
    @project = Project.loadModel( YAML.load( serial ) )
    @gui.update_project

    logger "serial: " + serial.inspect, 4

    @project.fileName = fileName
    @gui.refreshView
  end

  def saveAsProject(fileName)
    logger "saveAsProject: " + fileName
    if fileName.size > 0
      # Add file ending if it is not found
      fileName += FILE_ENDING if fileName.match(FILE_ENDING).nil?

      @project.fileName=fileName
      logger "SaveAs fileName:" + fileName
      saveProject
    end
  end

  def saveProject
    logger "save project"
    file = File.new @project.fileName, 'w'
    logger @project.inspect, 4
    @project.set_to_saved
    serial = YAML.dump( @project )
    logger "serial: " + serial.inspect, 4
    file.write serial
    file.close
    @gui.refreshTitle
    true
  end

end
