using afIoc
using fwt

internal class NavForwardCommand : GlobalCommand, RefluxEvents {
	@Inject	private History history
	
	new make(EventHub eventHub, |This|in) : super.make("afReflux.cmdNavForward", in) {
		eventHub.register(this)
		addEnabler("afReflux.cmdNavForward", |->Bool| { history.navForwardEnabled }, false )
	}
	
	override Void doInvoke(Event? event) {
		history.navForward
	}
	
	override Void onViewActivated	(View view) { update }
	override Void onViewDeactivated	(View view) { update } 
}
