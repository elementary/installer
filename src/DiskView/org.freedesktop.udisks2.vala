
namespace UDisks2 {

	[DBus (name = "org.freedesktop.UDisks2.PartitionTable")]
	public interface PartitionTable : GLib.Object {
		[DBus (name = "Type")]
		public abstract string type_name { owned get; set; }
		public abstract GLib.ObjectPath create_partition(uint64 offset, uint64 size, string type, string name, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract GLib.ObjectPath create_partition_and_format(uint64 offset, uint64 size, string type, string name, GLib.HashTable<string, GLib.Variant> options, string format_type, GLib.HashTable<string, GLib.Variant> format_options) throws DBusError, IOError;
	}

	[DBus (name = "org.freedesktop.UDisks2.Swapspace")]
	public interface Swapspace : GLib.Object {
		public abstract bool active { get; set; }
		public abstract void start(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void stop(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
	}

	[DBus (name = "org.freedesktop.UDisks2.Manager")]
	public interface Manager : GLib.Object {
		public abstract string version { owned get; set; }
		public abstract string[] supported_filesystems { owned get; set; }
		public abstract GLib.ObjectPath loop_setup(GLib.Variant fd, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		[DBus (name = "MDRaidCreate")]
		public abstract GLib.ObjectPath md_raid_create(GLib.ObjectPath[] blocks, string level, string name, uint64 chunk, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void enable_modules(bool enable) throws DBusError, IOError;
	}

	[DBus (name = "org.freedesktop.UDisks2.Encrypted")]
	public interface Encrypted : GLib.Object {
		public abstract EncryptedChildConfigurationStruct[] child_configuration { owned get; set; }
		public abstract GLib.ObjectPath unlock(string passphrase, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void @lock(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void change_passphrase(string passphrase, string new_passphrase, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
	}

	public struct EncryptedChildConfigurationStruct {
		public string attr1;
		public GLib.HashTable<string, GLib.Variant> attr2;
	}

	[DBus (name = "org.freedesktop.UDisks2.Drive")]
	public interface Drive : GLib.Object {
		public abstract string vendor { owned get; set; }
		public abstract string model { owned get; set; }
		public abstract string revision { owned get; set; }
		public abstract string serial { owned get; set; }
		[DBus (name = "WWN")]
		public abstract string wwn { owned get; set; }
		public abstract string id { owned get; set; }
		public abstract GLib.HashTable<string, GLib.Variant> configuration { owned get; }
		public abstract string media { owned get; set; }
		public abstract string[] media_compatibility { owned get; set; }
		public abstract bool media_removable { get; set; }
		public abstract bool media_available { get; set; }
		public abstract bool media_change_detected { get; set; }
		public abstract uint64 size { get; set; }
		public abstract uint64 time_detected { get; set; }
		public abstract uint64 time_media_detected { get; set; }
		public abstract bool optical { get; set; }
		public abstract bool optical_blank { get; set; }
		public abstract uint optical_num_tracks { get; set; }
		public abstract uint optical_num_audio_tracks { get; set; }
		public abstract uint optical_num_data_tracks { get; set; }
		public abstract uint optical_num_sessions { get; set; }
		public abstract int rotation_rate { get; set; }
		public abstract string connection_bus { owned get; set; }
		public abstract string seat { owned get; set; }
		public abstract bool removable { get; set; }
		public abstract bool ejectable { get; set; }
		public abstract string sort_key { owned get; set; }
		public abstract void eject(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void set_configuration(GLib.HashTable<string, GLib.Variant> value, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void power_off(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract bool can_power_off { get; set; }
		public abstract string sibling_id { owned get; set; }
	}

	[DBus (name = "org.freedesktop.UDisks2.Partition")]
	public interface Partition : GLib.Object {
		public abstract uint number { get; set; }
		[DBus (name = "Type")]
		public abstract string type_name { owned get; }
		public abstract uint64 flags { get; }
		public abstract uint64 offset { get; set; }
		public abstract uint64 size { get; set; }
		public abstract string name { owned get; }
		[DBus (name = "UUID")]
		public abstract string uuid { owned get; set; }
		public abstract GLib.ObjectPath table { owned get; set; }
		public abstract bool is_container { get; set; }
		public abstract bool is_contained { get; set; }
		public abstract void set_type(string type, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void set_name(string name, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void set_flags(uint64 flags, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void @delete(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
	}

	[DBus (name = "org.freedesktop.UDisks2.Filesystem")]
	public interface Filesystem : GLib.Object {
		public abstract void set_label(string label, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract uint8[,] mount_points { owned get; set; }
		public abstract string mount(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void unmount(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
	}

	[DBus (name = "org.freedesktop.UDisks2.Drive.Ata")]
	public interface DriveAta : GLib.Object {
		public abstract bool smart_supported { get; set; }
		public abstract bool smart_enabled { get; set; }
		public abstract uint64 smart_updated { get; set; }
		public abstract bool smart_failing { get; set; }
		public abstract uint64 smart_power_on_seconds { get; set; }
		public abstract double smart_temperature { get; set; }
		public abstract int smart_num_attributes_failing { get; set; }
		public abstract int smart_num_attributes_failed_in_the_past { get; set; }
		public abstract int64 smart_num_bad_sectors { get; set; }
		public abstract string smart_selftest_status { owned get; set; }
		public abstract int smart_selftest_percent_remaining { get; set; }
		public abstract void smart_update(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract DriveAtaAttributeStruct[] smart_get_attributes(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void smart_selftest_start(string type, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void smart_selftest_abort(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void smart_set_enabled(bool value, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract bool pm_supported { get; set; }
		public abstract bool pm_enabled { get; set; }
		public abstract bool apm_supported { get; set; }
		public abstract bool apm_enabled { get; set; }
		public abstract bool aam_supported { get; set; }
		public abstract bool aam_enabled { get; set; }
		public abstract int aam_vendor_recommended_value { get; set; }
		public abstract bool write_cache_supported { get; set; }
		public abstract bool write_cache_enabled { get; set; }
		public abstract bool read_lookahead_supported { get; set; }
		public abstract bool read_lookahead_enabled { get; set; }
		public abstract uint8 pm_get_state(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void pm_standby(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void pm_wakeup(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract int security_erase_unit_minutes { get; set; }
		public abstract int security_enhanced_erase_unit_minutes { get; set; }
		public abstract bool security_frozen { get; set; }
		public abstract void security_erase_unit(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
	}

	public struct DriveAtaAttributeStruct {
		public uint8 attr1;
		public string attr2;
		public uint attr3;
		public int attr4;
		public int attr5;
		public int attr6;
		public int64 attr7;
		public int attr8;
		public GLib.HashTable<string, GLib.Variant> attr9;
	}

	[DBus (name = "org.freedesktop.UDisks2.MDRaid")]
	public interface MDRaid : GLib.Object {
		[DBus (name = "UUID")]
		public abstract string uuid { owned get; set; }
		public abstract string name { owned get; set; }
		public abstract string level { owned get; set; }
		public abstract uint num_devices { get; set; }
		public abstract uint64 size { get; set; }
		public abstract string sync_action { owned get; set; }
		public abstract double sync_completed { get; set; }
		public abstract uint64 sync_rate { get; set; }
		public abstract uint64 sync_remaining_time { get; set; }
		public abstract uint degraded { get; set; }
		public abstract uint8[] bitmap_location { owned get; }
		public abstract uint64 chunk_size { get; set; }
		public abstract MDRaidActiveDeviceStruct[] active_devices { owned get; set; }
		public abstract MDRaidChildConfigurationStruct[] child_configuration { owned get; set; }
		public abstract bool running { get; set; }
		public abstract void start(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void stop(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void remove_device(GLib.ObjectPath device, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void add_device(GLib.ObjectPath device, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void set_bitmap_location(uint8[] value, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void request_sync_action(string sync_action, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void @delete(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
	}

	public struct MDRaidChildConfigurationStruct {
		public string attr1;
		public GLib.HashTable<string, GLib.Variant> attr2;
	}

	public struct MDRaidActiveDeviceStruct {
		public GLib.ObjectPath attr1;
		public int attr2;
		public string[] attr3;
		public string attr4;
		public uint64 attr5;
		public GLib.HashTable<string, GLib.Variant> attr6;
	}

	[DBus (name = "org.freedesktop.UDisks2.Loop")]
	public interface Loop : GLib.Object {
		public abstract void delete(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract uint8[] backing_file { owned get; set; }
		public abstract bool autoclear { get; }
		[DBus (name = "SetupByUID")]
		public abstract uint setup_by_uid { get; set; }
		public abstract void set_autoclear(bool value, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
	}

	[DBus (name = "org.freedesktop.UDisks2.Block")]
	public interface Block : GLib.Object {
		public abstract uint8[] device { owned get; set; }
		public abstract uint8[] preferred_device { owned get; set; }
		public abstract uint8[,] symlinks { owned get; set; }
		public abstract uint64 device_number { get; set; }
		public abstract string id { owned get; set; }
		public abstract uint64 size { get; set; }
		public abstract bool read_only { get; set; }
		[DBus (name = "Drive")]
		public abstract GLib.ObjectPath drive { owned get; }
		[DBus (name = "MDRaid")]
		public abstract GLib.ObjectPath md_raid { owned get; set; }
		[DBus (name = "MDRaidMember")]
		public abstract GLib.ObjectPath md_raid_member { owned get; set; }
		public abstract string id_usage { owned get; set; }
		public abstract string id_type { owned get; set; }
		public abstract string id_version { owned get; set; }
		public abstract string id_label { owned get; set; }
		[DBus (name = "IdUUID")]
		public abstract string id_uuid { owned get; set; }
		public abstract BlockConfigurationStruct[] configuration { owned get; set; }
		public abstract GLib.ObjectPath crypto_backing_device { owned get; set; }
		public abstract bool hint_partitionable { get; set; }
		public abstract bool hint_system { get; set; }
		public abstract bool hint_ignore { get; set; }
		public abstract bool hint_auto { get; set; }
		public abstract string hint_name { owned get; set; }
		public abstract string hint_icon_name { owned get; set; }
		public abstract string hint_symbolic_icon_name { owned get; set; }
		public abstract void add_configuration_item(BlockItemStruct item, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void remove_configuration_item(BlockItemStruct2 item, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void update_configuration_item(BlockOldItemStruct old_item, BlockNewItemStruct new_item, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract BlockConfigurationStruct2[] get_secret_configuration(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void format(string type, GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract GLib.Variant open_for_backup(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract GLib.Variant open_for_restore(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract GLib.Variant open_for_benchmark(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract void rescan(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
	}

	public struct BlockConfigurationStruct2 {
		public string attr1;
		public GLib.HashTable<string, GLib.Variant> attr2;
	}

	public struct BlockItemStruct {
		public string attr1;
		public GLib.HashTable<string, GLib.Variant> attr2;
	}

	public struct BlockOldItemStruct {
		public string attr1;
		public GLib.HashTable<string, GLib.Variant> attr2;
	}

	public struct BlockConfigurationStruct {
		public string attr1;
		public GLib.HashTable<string, GLib.Variant> attr2;
	}

	public struct BlockNewItemStruct {
		public string attr1;
		public GLib.HashTable<string, GLib.Variant> attr2;
	}

	public struct BlockItemStruct2 {
		public string attr1;
		public GLib.HashTable<string, GLib.Variant> attr2;
	}

	[DBus (name = "org.freedesktop.UDisks2.Job")]
	public interface Job : GLib.Object {
		public abstract string operation { owned get; set; }
		public abstract double progress { get; set; }
		public abstract bool progress_valid { get; set; }
		public abstract uint64 bytes { get; set; }
		public abstract uint64 rate { get; set; }
		public abstract uint64 start_time { get; set; }
		public abstract uint64 expected_end_time { get; set; }
		public abstract GLib.ObjectPath[] objects { owned get; set; }
		[DBus (name = "StartedByUID")]
		public abstract uint started_by_uid { get; set; }
		public abstract void cancel(GLib.HashTable<string, GLib.Variant> options) throws DBusError, IOError;
		public abstract bool cancelable { get; set; }
		public signal void completed(bool success, string message_);
	}
}
