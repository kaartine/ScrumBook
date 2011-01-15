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


class ScrumBController

  def initialize(project, gui)
    @project = project
    @gui = gui
  end

  def startApp
    fileName = nil
    ARGV.each do|a|
      if File.exists?(a)
        fileName = a
      else
        Tk.messageBox(
          'type'    => "ok",
          'icon'    => "info",
          'title'   => "Error opening file",
          'message' => "File \"#{a}\" doesn't exist!"
        )
      end
    end

    loadProject(fileName) unless fileName.nil?

    Tk.mainloop
  end

  def loadProject(fileName)
    if !File.exist?(fileName)
      return
    end
    file = File.new fileName, 'r'
    serial = file.read
    file.close
    @project.update( YAML.load( serial ) )
    logger @project.inspect

    @gui.project = @project

    logger "serial: " + serial.inspect, 4

    @project.fileName = fileName

    @gui.refreshView
  end

  def saveAsProject(fileName)
    if fileName.size > 0
      fileName += FILE_ENDING if fileName.match(FILE_ENDING).nil?

      @project.fileName=fileName
      logger "SaveAs fileName:" + fileName
      saveProject
    end
  end

  def saveProject
    file = File.new @project.fileName, 'w'
    @project.not_saved = false
    logger @project.inspect
    serial = YAML.dump( @project )
    logger "serial: " + serial.inspect, 4
    file.write serial
    file.close
    true
    @gui.refreshTitle
  end

end
