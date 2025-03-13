export type InstanceLike = {
	Destroy: (self: InstanceLike) -> ()
}
export type ReplicaCleanupTask = InstanceLike | () -> ()
export type ReplicaPath = {string} | string

export type ClassToken = {
	Class: string
}

export type Replication = "All" | Player | {[Player]: boolean}

export type CreateReplicaConfig<D,T,W> = {
	ClassToken: ClassToken,
	Data: D,
	Tags: T?,
	Replication: Replication?,
	WriteLib: W?,
	Parent: Replica?
}

export type Replica<D = {}, T = {}, W = {}> = {
	Data: D;
	Id: number;
	Class: string;
	Tags: T;
	Parent: unknown?;
	Children: {unknown};

	_replication: Replication,
	_creation_data: {any},
	_pending_replication: Replication,

	_write_lib: W?,
	_signal_listeners: {any},
	_maid: any,

	IsActive: (self: Replica<D,T,W>) -> boolean;
	Identify: (self: Replica<D,T,W>) -> string;
	AddCleanupTask: (self: Replica<D,T,W>, Task: ReplicaCleanupTask) -> ();
	RemoveCleanupTask: (self: Replica<D,T,W>, Task: ReplicaCleanupTask) -> ();
}

export type ServerReplica<D = {}, T = {}, W = {}> = Replica<D,T,W> & {
	SetValue: (self: ServerReplica<D,T,W>, Path: ReplicaPath, Value: unknown) -> ();
	SetValues: (self: ServerReplica<D,T,W>, Path: ReplicaPath, Values: {[unknown]: unknown}) -> ();
	ArrayInsert: (self: ServerReplica<D,T,W>, Path: ReplicaPath, Value: unknown) -> number;
	ArraySet: (self: ServerReplica<D,T,W>, Path: ReplicaPath, Index: number, Value: unknown) -> ();
	ArrayRemove: (self: ServerReplica<D,T,W>, Path: ReplicaPath, Index: number) -> unknown;

	Write: (self: ServerReplica<D,T,W>, Function: string, ...unknown) -> unknown;

	SetParent: (self: ServerReplica<D,T,W>, Parent: unknown) -> ();
	ReplicateFor: (self: ServerReplica<D,T,W>, Target: "All" | Player) -> ();
	DestroyFor: (self: ServerReplica<D,T,W>, Target: "All" | Player) -> ();
	ConnectOnServerEvent: (self: ServerReplica<D,T,W>, Callback: (Player: Player, ...unknown) -> ()) -> RBXScriptConnection;
	FireClient: (self: ServerReplica<D,T,W>, Player: Player, ...unknown) -> ();
	FireAllClients: (self: ServerReplica<D,T,W>, ...unknown) -> ();
	Destroy: (self: ServerReplica<D,T,W>) -> ();
}

export type ClientReplica<D = {}, T = {}, W = {}> = Replica<D,T,W> & {
	ListenToWrite: (self: ClientReplica<D,T,W>, Function: string, Callback: (...any) -> ()) -> RBXScriptConnection;
	ListenToChange: (self: ClientReplica<D,T,W>, Path: ReplicaPath, Callback: (New: any, Old: any) -> ()) -> RBXScriptConnection;
	ListenToNewKey: (self: ClientReplica<D,T,W>, Path: ReplicaPath, Callback: (Value: any, Key: string & number) -> ()) -> RBXScriptConnection;
	ListenToArrayInsert: (self: ClientReplica<D,T,W>, Path: ReplicaPath, Callback: (Index: any, Value: any) -> ()) -> RBXScriptConnection;
	ListenToArraySet: (self: ClientReplica<D,T,W>, Path: ReplicaPath, Callback: (Index: any, Value: any) -> ()) -> RBXScriptConnection;
	ListenToArrayRemove: (self: ClientReplica<D,T,W>, Path: ReplicaPath, Callback: (Index: any, Value: any) -> ()) -> RBXScriptConnection;
	ListenToRaw: (self: ClientReplica<D,T,W>, Callback: (Action: string, Path: ReplicaPath, ...any) -> ()) -> RBXScriptConnection;
	ListenToChildAdded: (self: ClientReplica<D,T,W>, Callback: (Child: any) -> ()) -> RBXScriptConnection;
	
	FindFirstChildOfClass: (self: ClientReplica<D,T,W>, Class: string) -> unknown?;
	ConnectOnClientEvent: (self: ClientReplica<D,T,W>, Callback: (...any) -> ()) -> RBXScriptConnection;
	FireServer: (self: ClientReplica<D,T,W>, ...unknown) -> ();
}

return {}