using afIoc

** (Service) -
** Loads / saves and maintains a cache of preference objects.
** Instances are cached until the backing file is updated / modified.
**
** Because Reflux is application centric, preference files are not associated
** with pods, but with the application name supplied at startup:
**
**   %FAN_HOME%/etc/<app-name>/xxx.fog
**
** Note that 'Preference' instances must be serializable and have an it-block ctor:
**   
**   new make(|This| f) { f(this) }
** 
@Js
mixin Preferences {

	** Returns an instance of the given preferences object.
	**
	**   syntax: fantom
	**   preferences.loadPrefs(MyPrefs#, "myPrefs.fog")
	abstract Obj loadPrefs(Type prefsType, Str? name := null)

	** Saves the given preference instance.
	**
	**   syntax: fantom
	**   preferences.savePrefs(myPrefs, "myPrefs.fog")
	abstract Void savePrefs(Obj prefs, Str? name := null)

	** Returns 'true' if the preferences file has been updated since it was last read.
	abstract Bool updated(Type prefsType, Str? name := null)

	** Finds the named file in the applications 'etc' dir.
	** If such a file does not exist, a file in the 'workDir' is returned.
	abstract File? findFile(Str name)

}

@Js
internal class PreferencesImpl : Preferences {
			private static const Log 	log 	:= Preferences#.pod.log
			private Str:CachedPrefs		cache	:= Str:CachedPrefs[:]
			private Str					appName
	@Inject private Scope				scope

	private new make(RegistryMeta regMeta, |This| in) {
		in(this)
		this.appName = regMeta[RefluxConstants.meta_appName].toStr.fromDisplayName
	}

	override Obj loadPrefs(Type prefsType, Str? name := null) {
		name = name ?: "${prefsType.name}.fog"
		cached	:= loadFromCache(name)

		if (cached != null) {
			log.debug("Returning cached $prefsType.name $cached")
			return cached
		}

		file	:= findFile(name)
		prefs 	:= loadFromFile(file)

		if (prefs == null) {
			log.debug("Making preferences: $prefsType.name")
			prefs = scope.build(prefsType)
		}

		cache[name] = CachedPrefs(file, prefs)

		return prefs
	}

	override Void savePrefs(Obj prefs, Str? name := null) {
		name = name ?: "${prefs.typeof.name}.fog"
		if (runtimeIsJs) {
			log.info("Cannot save $name in JS")
			return
		}
		file := findFile(name)
		file.writeObj(prefs, ["indent":2])
	}

	override Bool updated(Type prefsType, Str? name := null) {
		name = name ?: "${prefsType.name}.fog"
		return cache[name]?.modified ?: true
	}

	override File? findFile(Str name) {
		pathUri := `etc/${appName}/${name}`
		if (runtimeIsJs) {
			log.info("File $pathUri does not exist in Javascript land")
			return null
		}

		envFile := Env.cur.findFile(pathUri, false) ?: Env.cur.workDir + pathUri
		return envFile.normalize	// normalize gives the full absolute path
	}

	// ---- Private -------------------------------------------------------------------------------

	private Obj? loadFromCache(Str name) {
		cached 		:= cache[name]
		modified 	:= cached?.modified ?: true
		return modified ? null : cached.prefs
	}

	private Obj? loadFromFile(File? file) {
		Obj? value := null
		try {
			if (file != null && file.exists) {
				log.debug("Loading preferences: $file")
				value = file.readObj
				scope.inject(value)
			}
		} catch (Err e) {
			log.err("Cannot load options: $file", e)
		}
		return value
	}

	private static Bool runtimeIsJs() {
		Env.cur.runtime == "js"
	}
}

@Js
internal class CachedPrefs {
  	private File? 		file
  	private DateTime? 	modied
  			Obj 		prefs

	new make(File? f, Obj prefs) {
		this.file 	= f
		this.modied	= f?.modified
		this.prefs 	= prefs
  	}

	Bool modified() {
		if (file == null)
			return false
		return file.modified != modied
	}
}