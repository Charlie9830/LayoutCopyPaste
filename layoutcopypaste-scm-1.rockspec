package = "LayoutCopyPaste"
version = "scm-1"
source = {
   url = "*** please add URL for source tarball, zip or repository here ***"
}
description = {
   homepage = "*** please enter a project homepage ***",
   license = "*** please specify a license ***"
}
dependencies = {}
build = {
   type = "builtin",
   modules = {
      Dialogs = "Dialogs.lua"
      Mocks = "Mocks.lua"
      XmlUtils = "XmlUtils.lua"
      Merge = "Merge.lua"
      Builders = "Builders.lua"
      inspect = "inspect.lua"
      Query = "Query.lua"
      Utils = "Utils.lua"
      LayoutIO = "LayoutIO.lua"
      ExportImport = "ExportImport.lua",
      LayoutCopyPaste = "LayoutCopyPaste.lua",
      XmlParser = "XmlParser.lua",
      xml2lua = "xml2lua.lua",
      ["xmlhandler.dom"] = "xmlhandler/dom.lua",
      ["xmlhandler.print"] = "xmlhandler/print.lua",
      ["xmlhandler.tree"] = "xmlhandler/tree.lua"
   }
}
