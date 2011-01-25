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

class ProjectConfigurationView < TkFrame

  def initialize(tab)
    super(tab)

    @project = Project.create

    #project name
    nameEntry = TkEntry.new(self)
    @projectName = TkVariable.new
    @projectName.value = "Enter Project's name"
    nameEntry.textvariable = @projectName
    nameEntry.place('height' => 25,
            'width'  => 150,
            'x'      => 10,
            'y'      => 10)
  end

  def refreshView(selected_item = nil?)
    logger "TODO: refreshView not yet implemented for BurnDownView"
  end

  def update_project
    @project = Project.create
  end

  def bind_shortcuts(root)
    logger "TODO: bind_shortcuts not yet implemented for BurnDownView"
  end

end
