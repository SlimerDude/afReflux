using build
using fanr

class Build : BuildPod {

	new make() {
		podName = "afReflux"
		summary = "Flux - Reloaded"
		version = Version("0.0.1")

		meta = [
			"proj.name"		: "Reflux",
			"repo.private"	: "true",

			"afIoc.module"	: "afReflux::RefluxModule"
		]

		depends = [	
			"sys        1.0", 
			"gfx        1.0",
			"fwt        1.0",
			"concurrent 1.0",
			
			// ---- Core ------------------------
			"afBeanUtils  1.0.4  - 1.0", 
			"afConcurrent 1.0.8  - 1.0", 
			"afPlastic    1.0.16 - 1.0", 
			"afIoc        2.0.2  - 2.0"
		]

		srcDirs = [`fan/`, `fan/public/`, `fan/public/services/`, `fan/public/fwt/`, `fan/public/errors/`, `fan/public/advanced/`, `fan/internal/`, `fan/internal/commands/`]
		resDirs = [`locale/`, `res/icons-eclipse/`]
		
		javaDirs = [`java/`]
	}
}