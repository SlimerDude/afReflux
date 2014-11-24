using afIoc
using gfx
using fwt

internal class NewFolderCommand : RefluxCommand {
	@Inject	private Reflux	reflux
	private File	containingFolder

	new make(File containingFolder, |This|in) : super.make(in) {
		this.containingFolder = containingFolder
	}

	override Void invoked(Event? event) {
		dirName := Dialog.openPromptStr(reflux.window, "New Folder", "NewFolder")
		if (dirName != null) {
			containingFolder.createDir(dirName)
			reflux.refresh
		}
	}
}
