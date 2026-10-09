// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PlaylistsTable extends Playlists
    with TableInfo<$PlaylistsTable, PlaylistRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _m3uUrlMeta = const VerificationMeta('m3uUrl');
  @override
  late final GeneratedColumn<String> m3uUrl = GeneratedColumn<String>(
      'm3u_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _xtreamHostMeta =
      const VerificationMeta('xtreamHost');
  @override
  late final GeneratedColumn<String> xtreamHost = GeneratedColumn<String>(
      'xtream_host', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _xtreamUsernameMeta =
      const VerificationMeta('xtreamUsername');
  @override
  late final GeneratedColumn<String> xtreamUsername = GeneratedColumn<String>(
      'xtream_username', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _xtreamPasswordMeta =
      const VerificationMeta('xtreamPassword');
  @override
  late final GeneratedColumn<String> xtreamPassword = GeneratedColumn<String>(
      'xtream_password', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        type,
        m3uUrl,
        xtreamHost,
        xtreamUsername,
        xtreamPassword,
        createdAt,
        lastSyncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(Insertable<PlaylistRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('m3u_url')) {
      context.handle(_m3uUrlMeta,
          m3uUrl.isAcceptableOrUnknown(data['m3u_url']!, _m3uUrlMeta));
    }
    if (data.containsKey('xtream_host')) {
      context.handle(
          _xtreamHostMeta,
          xtreamHost.isAcceptableOrUnknown(
              data['xtream_host']!, _xtreamHostMeta));
    }
    if (data.containsKey('xtream_username')) {
      context.handle(
          _xtreamUsernameMeta,
          xtreamUsername.isAcceptableOrUnknown(
              data['xtream_username']!, _xtreamUsernameMeta));
    }
    if (data.containsKey('xtream_password')) {
      context.handle(
          _xtreamPasswordMeta,
          xtreamPassword.isAcceptableOrUnknown(
              data['xtream_password']!, _xtreamPasswordMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      m3uUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}m3u_url']),
      xtreamHost: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}xtream_host']),
      xtreamUsername: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}xtream_username']),
      xtreamPassword: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}xtream_password']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }
}

class PlaylistRow extends DataClass implements Insertable<PlaylistRow> {
  final String id;
  final String name;
  final String type;
  final String? m3uUrl;
  final String? xtreamHost;
  final String? xtreamUsername;
  final String? xtreamPassword;
  final DateTime createdAt;
  final DateTime? lastSyncedAt;
  const PlaylistRow(
      {required this.id,
      required this.name,
      required this.type,
      this.m3uUrl,
      this.xtreamHost,
      this.xtreamUsername,
      this.xtreamPassword,
      required this.createdAt,
      this.lastSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || m3uUrl != null) {
      map['m3u_url'] = Variable<String>(m3uUrl);
    }
    if (!nullToAbsent || xtreamHost != null) {
      map['xtream_host'] = Variable<String>(xtreamHost);
    }
    if (!nullToAbsent || xtreamUsername != null) {
      map['xtream_username'] = Variable<String>(xtreamUsername);
    }
    if (!nullToAbsent || xtreamPassword != null) {
      map['xtream_password'] = Variable<String>(xtreamPassword);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      m3uUrl:
          m3uUrl == null && nullToAbsent ? const Value.absent() : Value(m3uUrl),
      xtreamHost: xtreamHost == null && nullToAbsent
          ? const Value.absent()
          : Value(xtreamHost),
      xtreamUsername: xtreamUsername == null && nullToAbsent
          ? const Value.absent()
          : Value(xtreamUsername),
      xtreamPassword: xtreamPassword == null && nullToAbsent
          ? const Value.absent()
          : Value(xtreamPassword),
      createdAt: Value(createdAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory PlaylistRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      m3uUrl: serializer.fromJson<String?>(json['m3uUrl']),
      xtreamHost: serializer.fromJson<String?>(json['xtreamHost']),
      xtreamUsername: serializer.fromJson<String?>(json['xtreamUsername']),
      xtreamPassword: serializer.fromJson<String?>(json['xtreamPassword']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'm3uUrl': serializer.toJson<String?>(m3uUrl),
      'xtreamHost': serializer.toJson<String?>(xtreamHost),
      'xtreamUsername': serializer.toJson<String?>(xtreamUsername),
      'xtreamPassword': serializer.toJson<String?>(xtreamPassword),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  PlaylistRow copyWith(
          {String? id,
          String? name,
          String? type,
          Value<String?> m3uUrl = const Value.absent(),
          Value<String?> xtreamHost = const Value.absent(),
          Value<String?> xtreamUsername = const Value.absent(),
          Value<String?> xtreamPassword = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> lastSyncedAt = const Value.absent()}) =>
      PlaylistRow(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        m3uUrl: m3uUrl.present ? m3uUrl.value : this.m3uUrl,
        xtreamHost: xtreamHost.present ? xtreamHost.value : this.xtreamHost,
        xtreamUsername:
            xtreamUsername.present ? xtreamUsername.value : this.xtreamUsername,
        xtreamPassword:
            xtreamPassword.present ? xtreamPassword.value : this.xtreamPassword,
        createdAt: createdAt ?? this.createdAt,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
      );
  PlaylistRow copyWithCompanion(PlaylistsCompanion data) {
    return PlaylistRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      m3uUrl: data.m3uUrl.present ? data.m3uUrl.value : this.m3uUrl,
      xtreamHost:
          data.xtreamHost.present ? data.xtreamHost.value : this.xtreamHost,
      xtreamUsername: data.xtreamUsername.present
          ? data.xtreamUsername.value
          : this.xtreamUsername,
      xtreamPassword: data.xtreamPassword.present
          ? data.xtreamPassword.value
          : this.xtreamPassword,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('m3uUrl: $m3uUrl, ')
          ..write('xtreamHost: $xtreamHost, ')
          ..write('xtreamUsername: $xtreamUsername, ')
          ..write('xtreamPassword: $xtreamPassword, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, m3uUrl, xtreamHost,
      xtreamUsername, xtreamPassword, createdAt, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.m3uUrl == this.m3uUrl &&
          other.xtreamHost == this.xtreamHost &&
          other.xtreamUsername == this.xtreamUsername &&
          other.xtreamPassword == this.xtreamPassword &&
          other.createdAt == this.createdAt &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class PlaylistsCompanion extends UpdateCompanion<PlaylistRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> m3uUrl;
  final Value<String?> xtreamHost;
  final Value<String?> xtreamUsername;
  final Value<String?> xtreamPassword;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.m3uUrl = const Value.absent(),
    this.xtreamHost = const Value.absent(),
    this.xtreamUsername = const Value.absent(),
    this.xtreamPassword = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    required String id,
    required String name,
    required String type,
    this.m3uUrl = const Value.absent(),
    this.xtreamHost = const Value.absent(),
    this.xtreamUsername = const Value.absent(),
    this.xtreamPassword = const Value.absent(),
    required DateTime createdAt,
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        type = Value(type),
        createdAt = Value(createdAt);
  static Insertable<PlaylistRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? m3uUrl,
    Expression<String>? xtreamHost,
    Expression<String>? xtreamUsername,
    Expression<String>? xtreamPassword,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (m3uUrl != null) 'm3u_url': m3uUrl,
      if (xtreamHost != null) 'xtream_host': xtreamHost,
      if (xtreamUsername != null) 'xtream_username': xtreamUsername,
      if (xtreamPassword != null) 'xtream_password': xtreamPassword,
      if (createdAt != null) 'created_at': createdAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? type,
      Value<String?>? m3uUrl,
      Value<String?>? xtreamHost,
      Value<String?>? xtreamUsername,
      Value<String?>? xtreamPassword,
      Value<DateTime>? createdAt,
      Value<DateTime?>? lastSyncedAt,
      Value<int>? rowid}) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      m3uUrl: m3uUrl ?? this.m3uUrl,
      xtreamHost: xtreamHost ?? this.xtreamHost,
      xtreamUsername: xtreamUsername ?? this.xtreamUsername,
      xtreamPassword: xtreamPassword ?? this.xtreamPassword,
      createdAt: createdAt ?? this.createdAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (m3uUrl.present) {
      map['m3u_url'] = Variable<String>(m3uUrl.value);
    }
    if (xtreamHost.present) {
      map['xtream_host'] = Variable<String>(xtreamHost.value);
    }
    if (xtreamUsername.present) {
      map['xtream_username'] = Variable<String>(xtreamUsername.value);
    }
    if (xtreamPassword.present) {
      map['xtream_password'] = Variable<String>(xtreamPassword.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('m3uUrl: $m3uUrl, ')
          ..write('xtreamHost: $xtreamHost, ')
          ..write('xtreamUsername: $xtreamUsername, ')
          ..write('xtreamPassword: $xtreamPassword, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChannelsTable extends Channels
    with TableInfo<$ChannelsTable, ChannelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _playlistIdMeta =
      const VerificationMeta('playlistId');
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
      'playlist_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _logoUrlMeta =
      const VerificationMeta('logoUrl');
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
      'logo_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _streamUrlMeta =
      const VerificationMeta('streamUrl');
  @override
  late final GeneratedColumn<String> streamUrl = GeneratedColumn<String>(
      'stream_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, playlistId, name, logoUrl, category, streamUrl, isFavorite];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channels';
  @override
  VerificationContext validateIntegrity(Insertable<ChannelRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
          _playlistIdMeta,
          playlistId.isAcceptableOrUnknown(
              data['playlist_id']!, _playlistIdMeta));
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('logo_url')) {
      context.handle(_logoUrlMeta,
          logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('stream_url')) {
      context.handle(_streamUrlMeta,
          streamUrl.isAcceptableOrUnknown(data['stream_url']!, _streamUrlMeta));
    } else if (isInserting) {
      context.missing(_streamUrlMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChannelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChannelRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      playlistId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}playlist_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      logoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}logo_url']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      streamUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stream_url'])!,
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
    );
  }

  @override
  $ChannelsTable createAlias(String alias) {
    return $ChannelsTable(attachedDatabase, alias);
  }
}

class ChannelRow extends DataClass implements Insertable<ChannelRow> {
  final String id;
  final String playlistId;
  final String name;
  final String? logoUrl;
  final String? category;
  final String streamUrl;
  final bool isFavorite;
  const ChannelRow(
      {required this.id,
      required this.playlistId,
      required this.name,
      this.logoUrl,
      this.category,
      required this.streamUrl,
      required this.isFavorite});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || logoUrl != null) {
      map['logo_url'] = Variable<String>(logoUrl);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['stream_url'] = Variable<String>(streamUrl);
    map['is_favorite'] = Variable<bool>(isFavorite);
    return map;
  }

  ChannelsCompanion toCompanion(bool nullToAbsent) {
    return ChannelsCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      name: Value(name),
      logoUrl: logoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(logoUrl),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      streamUrl: Value(streamUrl),
      isFavorite: Value(isFavorite),
    );
  }

  factory ChannelRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChannelRow(
      id: serializer.fromJson<String>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      name: serializer.fromJson<String>(json['name']),
      logoUrl: serializer.fromJson<String?>(json['logoUrl']),
      category: serializer.fromJson<String?>(json['category']),
      streamUrl: serializer.fromJson<String>(json['streamUrl']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'playlistId': serializer.toJson<String>(playlistId),
      'name': serializer.toJson<String>(name),
      'logoUrl': serializer.toJson<String?>(logoUrl),
      'category': serializer.toJson<String?>(category),
      'streamUrl': serializer.toJson<String>(streamUrl),
      'isFavorite': serializer.toJson<bool>(isFavorite),
    };
  }

  ChannelRow copyWith(
          {String? id,
          String? playlistId,
          String? name,
          Value<String?> logoUrl = const Value.absent(),
          Value<String?> category = const Value.absent(),
          String? streamUrl,
          bool? isFavorite}) =>
      ChannelRow(
        id: id ?? this.id,
        playlistId: playlistId ?? this.playlistId,
        name: name ?? this.name,
        logoUrl: logoUrl.present ? logoUrl.value : this.logoUrl,
        category: category.present ? category.value : this.category,
        streamUrl: streamUrl ?? this.streamUrl,
        isFavorite: isFavorite ?? this.isFavorite,
      );
  ChannelRow copyWithCompanion(ChannelsCompanion data) {
    return ChannelRow(
      id: data.id.present ? data.id.value : this.id,
      playlistId:
          data.playlistId.present ? data.playlistId.value : this.playlistId,
      name: data.name.present ? data.name.value : this.name,
      logoUrl: data.logoUrl.present ? data.logoUrl.value : this.logoUrl,
      category: data.category.present ? data.category.value : this.category,
      streamUrl: data.streamUrl.present ? data.streamUrl.value : this.streamUrl,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChannelRow(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('name: $name, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('category: $category, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, playlistId, name, logoUrl, category, streamUrl, isFavorite);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelRow &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.name == this.name &&
          other.logoUrl == this.logoUrl &&
          other.category == this.category &&
          other.streamUrl == this.streamUrl &&
          other.isFavorite == this.isFavorite);
}

class ChannelsCompanion extends UpdateCompanion<ChannelRow> {
  final Value<String> id;
  final Value<String> playlistId;
  final Value<String> name;
  final Value<String?> logoUrl;
  final Value<String?> category;
  final Value<String> streamUrl;
  final Value<bool> isFavorite;
  final Value<int> rowid;
  const ChannelsCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.name = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.category = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChannelsCompanion.insert({
    required String id,
    required String playlistId,
    required String name,
    this.logoUrl = const Value.absent(),
    this.category = const Value.absent(),
    required String streamUrl,
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        playlistId = Value(playlistId),
        name = Value(name),
        streamUrl = Value(streamUrl);
  static Insertable<ChannelRow> custom({
    Expression<String>? id,
    Expression<String>? playlistId,
    Expression<String>? name,
    Expression<String>? logoUrl,
    Expression<String>? category,
    Expression<String>? streamUrl,
    Expression<bool>? isFavorite,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (name != null) 'name': name,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (category != null) 'category': category,
      if (streamUrl != null) 'stream_url': streamUrl,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChannelsCompanion copyWith(
      {Value<String>? id,
      Value<String>? playlistId,
      Value<String>? name,
      Value<String?>? logoUrl,
      Value<String?>? category,
      Value<String>? streamUrl,
      Value<bool>? isFavorite,
      Value<int>? rowid}) {
    return ChannelsCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      category: category ?? this.category,
      streamUrl: streamUrl ?? this.streamUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (streamUrl.present) {
      map['stream_url'] = Variable<String>(streamUrl.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelsCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('name: $name, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('category: $category, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MoviesTable extends Movies with TableInfo<$MoviesTable, MovieRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoviesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _playlistIdMeta =
      const VerificationMeta('playlistId');
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
      'playlist_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _posterUrlMeta =
      const VerificationMeta('posterUrl');
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
      'poster_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _streamUrlMeta =
      const VerificationMeta('streamUrl');
  @override
  late final GeneratedColumn<String> streamUrl = GeneratedColumn<String>(
      'stream_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _extensionMeta =
      const VerificationMeta('extension');
  @override
  late final GeneratedColumn<String> extension = GeneratedColumn<String>(
      'extension', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        playlistId,
        title,
        posterUrl,
        category,
        streamUrl,
        extension,
        isFavorite
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movies';
  @override
  VerificationContext validateIntegrity(Insertable<MovieRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
          _playlistIdMeta,
          playlistId.isAcceptableOrUnknown(
              data['playlist_id']!, _playlistIdMeta));
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('poster_url')) {
      context.handle(_posterUrlMeta,
          posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('stream_url')) {
      context.handle(_streamUrlMeta,
          streamUrl.isAcceptableOrUnknown(data['stream_url']!, _streamUrlMeta));
    } else if (isInserting) {
      context.missing(_streamUrlMeta);
    }
    if (data.containsKey('extension')) {
      context.handle(_extensionMeta,
          extension.isAcceptableOrUnknown(data['extension']!, _extensionMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MovieRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MovieRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      playlistId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}playlist_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      posterUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}poster_url']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      streamUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stream_url'])!,
      extension: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}extension']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
    );
  }

  @override
  $MoviesTable createAlias(String alias) {
    return $MoviesTable(attachedDatabase, alias);
  }
}

class MovieRow extends DataClass implements Insertable<MovieRow> {
  final String id;
  final String playlistId;
  final String title;
  final String? posterUrl;
  final String? category;
  final String streamUrl;
  final String? extension;
  final bool isFavorite;
  const MovieRow(
      {required this.id,
      required this.playlistId,
      required this.title,
      this.posterUrl,
      this.category,
      required this.streamUrl,
      this.extension,
      required this.isFavorite});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || posterUrl != null) {
      map['poster_url'] = Variable<String>(posterUrl);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['stream_url'] = Variable<String>(streamUrl);
    if (!nullToAbsent || extension != null) {
      map['extension'] = Variable<String>(extension);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    return map;
  }

  MoviesCompanion toCompanion(bool nullToAbsent) {
    return MoviesCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      title: Value(title),
      posterUrl: posterUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(posterUrl),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      streamUrl: Value(streamUrl),
      extension: extension == null && nullToAbsent
          ? const Value.absent()
          : Value(extension),
      isFavorite: Value(isFavorite),
    );
  }

  factory MovieRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MovieRow(
      id: serializer.fromJson<String>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      title: serializer.fromJson<String>(json['title']),
      posterUrl: serializer.fromJson<String?>(json['posterUrl']),
      category: serializer.fromJson<String?>(json['category']),
      streamUrl: serializer.fromJson<String>(json['streamUrl']),
      extension: serializer.fromJson<String?>(json['extension']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'playlistId': serializer.toJson<String>(playlistId),
      'title': serializer.toJson<String>(title),
      'posterUrl': serializer.toJson<String?>(posterUrl),
      'category': serializer.toJson<String?>(category),
      'streamUrl': serializer.toJson<String>(streamUrl),
      'extension': serializer.toJson<String?>(extension),
      'isFavorite': serializer.toJson<bool>(isFavorite),
    };
  }

  MovieRow copyWith(
          {String? id,
          String? playlistId,
          String? title,
          Value<String?> posterUrl = const Value.absent(),
          Value<String?> category = const Value.absent(),
          String? streamUrl,
          Value<String?> extension = const Value.absent(),
          bool? isFavorite}) =>
      MovieRow(
        id: id ?? this.id,
        playlistId: playlistId ?? this.playlistId,
        title: title ?? this.title,
        posterUrl: posterUrl.present ? posterUrl.value : this.posterUrl,
        category: category.present ? category.value : this.category,
        streamUrl: streamUrl ?? this.streamUrl,
        extension: extension.present ? extension.value : this.extension,
        isFavorite: isFavorite ?? this.isFavorite,
      );
  MovieRow copyWithCompanion(MoviesCompanion data) {
    return MovieRow(
      id: data.id.present ? data.id.value : this.id,
      playlistId:
          data.playlistId.present ? data.playlistId.value : this.playlistId,
      title: data.title.present ? data.title.value : this.title,
      posterUrl: data.posterUrl.present ? data.posterUrl.value : this.posterUrl,
      category: data.category.present ? data.category.value : this.category,
      streamUrl: data.streamUrl.present ? data.streamUrl.value : this.streamUrl,
      extension: data.extension.present ? data.extension.value : this.extension,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MovieRow(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('title: $title, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('category: $category, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('extension: $extension, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, playlistId, title, posterUrl, category,
      streamUrl, extension, isFavorite);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MovieRow &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.title == this.title &&
          other.posterUrl == this.posterUrl &&
          other.category == this.category &&
          other.streamUrl == this.streamUrl &&
          other.extension == this.extension &&
          other.isFavorite == this.isFavorite);
}

class MoviesCompanion extends UpdateCompanion<MovieRow> {
  final Value<String> id;
  final Value<String> playlistId;
  final Value<String> title;
  final Value<String?> posterUrl;
  final Value<String?> category;
  final Value<String> streamUrl;
  final Value<String?> extension;
  final Value<bool> isFavorite;
  final Value<int> rowid;
  const MoviesCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.title = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.category = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.extension = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MoviesCompanion.insert({
    required String id,
    required String playlistId,
    required String title,
    this.posterUrl = const Value.absent(),
    this.category = const Value.absent(),
    required String streamUrl,
    this.extension = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        playlistId = Value(playlistId),
        title = Value(title),
        streamUrl = Value(streamUrl);
  static Insertable<MovieRow> custom({
    Expression<String>? id,
    Expression<String>? playlistId,
    Expression<String>? title,
    Expression<String>? posterUrl,
    Expression<String>? category,
    Expression<String>? streamUrl,
    Expression<String>? extension,
    Expression<bool>? isFavorite,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (title != null) 'title': title,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (category != null) 'category': category,
      if (streamUrl != null) 'stream_url': streamUrl,
      if (extension != null) 'extension': extension,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MoviesCompanion copyWith(
      {Value<String>? id,
      Value<String>? playlistId,
      Value<String>? title,
      Value<String?>? posterUrl,
      Value<String?>? category,
      Value<String>? streamUrl,
      Value<String?>? extension,
      Value<bool>? isFavorite,
      Value<int>? rowid}) {
    return MoviesCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      title: title ?? this.title,
      posterUrl: posterUrl ?? this.posterUrl,
      category: category ?? this.category,
      streamUrl: streamUrl ?? this.streamUrl,
      extension: extension ?? this.extension,
      isFavorite: isFavorite ?? this.isFavorite,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (streamUrl.present) {
      map['stream_url'] = Variable<String>(streamUrl.value);
    }
    if (extension.present) {
      map['extension'] = Variable<String>(extension.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoviesCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('title: $title, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('category: $category, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('extension: $extension, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeriesTableTable extends SeriesTable
    with TableInfo<$SeriesTableTable, SeriesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _playlistIdMeta =
      const VerificationMeta('playlistId');
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
      'playlist_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _posterUrlMeta =
      const VerificationMeta('posterUrl');
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
      'poster_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, playlistId, title, posterUrl, category, isFavorite];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'series_table';
  @override
  VerificationContext validateIntegrity(Insertable<SeriesRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
          _playlistIdMeta,
          playlistId.isAcceptableOrUnknown(
              data['playlist_id']!, _playlistIdMeta));
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('poster_url')) {
      context.handle(_posterUrlMeta,
          posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SeriesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeriesRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      playlistId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}playlist_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      posterUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}poster_url']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
    );
  }

  @override
  $SeriesTableTable createAlias(String alias) {
    return $SeriesTableTable(attachedDatabase, alias);
  }
}

class SeriesRow extends DataClass implements Insertable<SeriesRow> {
  final String id;
  final String playlistId;
  final String title;
  final String? posterUrl;
  final String? category;
  final bool isFavorite;
  const SeriesRow(
      {required this.id,
      required this.playlistId,
      required this.title,
      this.posterUrl,
      this.category,
      required this.isFavorite});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || posterUrl != null) {
      map['poster_url'] = Variable<String>(posterUrl);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    return map;
  }

  SeriesTableCompanion toCompanion(bool nullToAbsent) {
    return SeriesTableCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      title: Value(title),
      posterUrl: posterUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(posterUrl),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      isFavorite: Value(isFavorite),
    );
  }

  factory SeriesRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeriesRow(
      id: serializer.fromJson<String>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      title: serializer.fromJson<String>(json['title']),
      posterUrl: serializer.fromJson<String?>(json['posterUrl']),
      category: serializer.fromJson<String?>(json['category']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'playlistId': serializer.toJson<String>(playlistId),
      'title': serializer.toJson<String>(title),
      'posterUrl': serializer.toJson<String?>(posterUrl),
      'category': serializer.toJson<String?>(category),
      'isFavorite': serializer.toJson<bool>(isFavorite),
    };
  }

  SeriesRow copyWith(
          {String? id,
          String? playlistId,
          String? title,
          Value<String?> posterUrl = const Value.absent(),
          Value<String?> category = const Value.absent(),
          bool? isFavorite}) =>
      SeriesRow(
        id: id ?? this.id,
        playlistId: playlistId ?? this.playlistId,
        title: title ?? this.title,
        posterUrl: posterUrl.present ? posterUrl.value : this.posterUrl,
        category: category.present ? category.value : this.category,
        isFavorite: isFavorite ?? this.isFavorite,
      );
  SeriesRow copyWithCompanion(SeriesTableCompanion data) {
    return SeriesRow(
      id: data.id.present ? data.id.value : this.id,
      playlistId:
          data.playlistId.present ? data.playlistId.value : this.playlistId,
      title: data.title.present ? data.title.value : this.title,
      posterUrl: data.posterUrl.present ? data.posterUrl.value : this.posterUrl,
      category: data.category.present ? data.category.value : this.category,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesRow(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('title: $title, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('category: $category, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, playlistId, title, posterUrl, category, isFavorite);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesRow &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.title == this.title &&
          other.posterUrl == this.posterUrl &&
          other.category == this.category &&
          other.isFavorite == this.isFavorite);
}

class SeriesTableCompanion extends UpdateCompanion<SeriesRow> {
  final Value<String> id;
  final Value<String> playlistId;
  final Value<String> title;
  final Value<String?> posterUrl;
  final Value<String?> category;
  final Value<bool> isFavorite;
  final Value<int> rowid;
  const SeriesTableCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.title = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.category = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeriesTableCompanion.insert({
    required String id,
    required String playlistId,
    required String title,
    this.posterUrl = const Value.absent(),
    this.category = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        playlistId = Value(playlistId),
        title = Value(title);
  static Insertable<SeriesRow> custom({
    Expression<String>? id,
    Expression<String>? playlistId,
    Expression<String>? title,
    Expression<String>? posterUrl,
    Expression<String>? category,
    Expression<bool>? isFavorite,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (title != null) 'title': title,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (category != null) 'category': category,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeriesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? playlistId,
      Value<String>? title,
      Value<String?>? posterUrl,
      Value<String?>? category,
      Value<bool>? isFavorite,
      Value<int>? rowid}) {
    return SeriesTableCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      title: title ?? this.title,
      posterUrl: posterUrl ?? this.posterUrl,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeriesTableCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('title: $title, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('category: $category, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EpisodesTable extends Episodes
    with TableInfo<$EpisodesTable, EpisodeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _seriesIdMeta =
      const VerificationMeta('seriesId');
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
      'series_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _seasonNumberMeta =
      const VerificationMeta('seasonNumber');
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
      'season_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _episodeNumberMeta =
      const VerificationMeta('episodeNumber');
  @override
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
      'episode_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _streamUrlMeta =
      const VerificationMeta('streamUrl');
  @override
  late final GeneratedColumn<String> streamUrl = GeneratedColumn<String>(
      'stream_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _extensionMeta =
      const VerificationMeta('extension');
  @override
  late final GeneratedColumn<String> extension = GeneratedColumn<String>(
      'extension', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, seriesId, seasonNumber, episodeNumber, title, streamUrl, extension];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodes';
  @override
  VerificationContext validateIntegrity(Insertable<EpisodeRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(_seriesIdMeta,
          seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta));
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(
          _seasonNumberMeta,
          seasonNumber.isAcceptableOrUnknown(
              data['season_number']!, _seasonNumberMeta));
    } else if (isInserting) {
      context.missing(_seasonNumberMeta);
    }
    if (data.containsKey('episode_number')) {
      context.handle(
          _episodeNumberMeta,
          episodeNumber.isAcceptableOrUnknown(
              data['episode_number']!, _episodeNumberMeta));
    } else if (isInserting) {
      context.missing(_episodeNumberMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('stream_url')) {
      context.handle(_streamUrlMeta,
          streamUrl.isAcceptableOrUnknown(data['stream_url']!, _streamUrlMeta));
    } else if (isInserting) {
      context.missing(_streamUrlMeta);
    }
    if (data.containsKey('extension')) {
      context.handle(_extensionMeta,
          extension.isAcceptableOrUnknown(data['extension']!, _extensionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EpisodeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpisodeRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      seriesId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}series_id'])!,
      seasonNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}season_number'])!,
      episodeNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}episode_number'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      streamUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stream_url'])!,
      extension: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}extension']),
    );
  }

  @override
  $EpisodesTable createAlias(String alias) {
    return $EpisodesTable(attachedDatabase, alias);
  }
}

class EpisodeRow extends DataClass implements Insertable<EpisodeRow> {
  final String id;
  final String seriesId;
  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final String streamUrl;
  final String? extension;
  const EpisodeRow(
      {required this.id,
      required this.seriesId,
      required this.seasonNumber,
      required this.episodeNumber,
      required this.title,
      required this.streamUrl,
      this.extension});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['series_id'] = Variable<String>(seriesId);
    map['season_number'] = Variable<int>(seasonNumber);
    map['episode_number'] = Variable<int>(episodeNumber);
    map['title'] = Variable<String>(title);
    map['stream_url'] = Variable<String>(streamUrl);
    if (!nullToAbsent || extension != null) {
      map['extension'] = Variable<String>(extension);
    }
    return map;
  }

  EpisodesCompanion toCompanion(bool nullToAbsent) {
    return EpisodesCompanion(
      id: Value(id),
      seriesId: Value(seriesId),
      seasonNumber: Value(seasonNumber),
      episodeNumber: Value(episodeNumber),
      title: Value(title),
      streamUrl: Value(streamUrl),
      extension: extension == null && nullToAbsent
          ? const Value.absent()
          : Value(extension),
    );
  }

  factory EpisodeRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpisodeRow(
      id: serializer.fromJson<String>(json['id']),
      seriesId: serializer.fromJson<String>(json['seriesId']),
      seasonNumber: serializer.fromJson<int>(json['seasonNumber']),
      episodeNumber: serializer.fromJson<int>(json['episodeNumber']),
      title: serializer.fromJson<String>(json['title']),
      streamUrl: serializer.fromJson<String>(json['streamUrl']),
      extension: serializer.fromJson<String?>(json['extension']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'seriesId': serializer.toJson<String>(seriesId),
      'seasonNumber': serializer.toJson<int>(seasonNumber),
      'episodeNumber': serializer.toJson<int>(episodeNumber),
      'title': serializer.toJson<String>(title),
      'streamUrl': serializer.toJson<String>(streamUrl),
      'extension': serializer.toJson<String?>(extension),
    };
  }

  EpisodeRow copyWith(
          {String? id,
          String? seriesId,
          int? seasonNumber,
          int? episodeNumber,
          String? title,
          String? streamUrl,
          Value<String?> extension = const Value.absent()}) =>
      EpisodeRow(
        id: id ?? this.id,
        seriesId: seriesId ?? this.seriesId,
        seasonNumber: seasonNumber ?? this.seasonNumber,
        episodeNumber: episodeNumber ?? this.episodeNumber,
        title: title ?? this.title,
        streamUrl: streamUrl ?? this.streamUrl,
        extension: extension.present ? extension.value : this.extension,
      );
  EpisodeRow copyWithCompanion(EpisodesCompanion data) {
    return EpisodeRow(
      id: data.id.present ? data.id.value : this.id,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      episodeNumber: data.episodeNumber.present
          ? data.episodeNumber.value
          : this.episodeNumber,
      title: data.title.present ? data.title.value : this.title,
      streamUrl: data.streamUrl.present ? data.streamUrl.value : this.streamUrl,
      extension: data.extension.present ? data.extension.value : this.extension,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpisodeRow(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('title: $title, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('extension: $extension')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, seriesId, seasonNumber, episodeNumber, title, streamUrl, extension);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpisodeRow &&
          other.id == this.id &&
          other.seriesId == this.seriesId &&
          other.seasonNumber == this.seasonNumber &&
          other.episodeNumber == this.episodeNumber &&
          other.title == this.title &&
          other.streamUrl == this.streamUrl &&
          other.extension == this.extension);
}

class EpisodesCompanion extends UpdateCompanion<EpisodeRow> {
  final Value<String> id;
  final Value<String> seriesId;
  final Value<int> seasonNumber;
  final Value<int> episodeNumber;
  final Value<String> title;
  final Value<String> streamUrl;
  final Value<String?> extension;
  final Value<int> rowid;
  const EpisodesCompanion({
    this.id = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.title = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.extension = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EpisodesCompanion.insert({
    required String id,
    required String seriesId,
    required int seasonNumber,
    required int episodeNumber,
    required String title,
    required String streamUrl,
    this.extension = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        seriesId = Value(seriesId),
        seasonNumber = Value(seasonNumber),
        episodeNumber = Value(episodeNumber),
        title = Value(title),
        streamUrl = Value(streamUrl);
  static Insertable<EpisodeRow> custom({
    Expression<String>? id,
    Expression<String>? seriesId,
    Expression<int>? seasonNumber,
    Expression<int>? episodeNumber,
    Expression<String>? title,
    Expression<String>? streamUrl,
    Expression<String>? extension,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seriesId != null) 'series_id': seriesId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (title != null) 'title': title,
      if (streamUrl != null) 'stream_url': streamUrl,
      if (extension != null) 'extension': extension,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EpisodesCompanion copyWith(
      {Value<String>? id,
      Value<String>? seriesId,
      Value<int>? seasonNumber,
      Value<int>? episodeNumber,
      Value<String>? title,
      Value<String>? streamUrl,
      Value<String?>? extension,
      Value<int>? rowid}) {
    return EpisodesCompanion(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      streamUrl: streamUrl ?? this.streamUrl,
      extension: extension ?? this.extension,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (streamUrl.present) {
      map['stream_url'] = Variable<String>(streamUrl.value);
    }
    if (extension.present) {
      map['extension'] = Variable<String>(extension.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodesCompanion(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('title: $title, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('extension: $extension, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadsTable extends Downloads
    with TableInfo<$DownloadsTable, DownloadRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceUrlMeta =
      const VerificationMeta('sourceUrl');
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
      'source_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentTypeMeta =
      const VerificationMeta('contentType');
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
      'content_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('queued'));
  static const VerificationMeta _progressMeta =
      const VerificationMeta('progress');
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
      'progress', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalBytesMeta =
      const VerificationMeta('totalBytes');
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
      'total_bytes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _downloadedBytesMeta =
      const VerificationMeta('downloadedBytes');
  @override
  late final GeneratedColumn<int> downloadedBytes = GeneratedColumn<int>(
      'downloaded_bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sourceUrl,
        title,
        contentType,
        localPath,
        status,
        progress,
        totalBytes,
        downloadedBytes,
        addedAt,
        errorMessage
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(Insertable<DownloadRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_url')) {
      context.handle(_sourceUrlMeta,
          sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta));
    } else if (isInserting) {
      context.missing(_sourceUrlMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
          _contentTypeMeta,
          contentType.isAcceptableOrUnknown(
              data['content_type']!, _contentTypeMeta));
    } else if (isInserting) {
      context.missing(_contentTypeMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('progress')) {
      context.handle(_progressMeta,
          progress.isAcceptableOrUnknown(data['progress']!, _progressMeta));
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
          _totalBytesMeta,
          totalBytes.isAcceptableOrUnknown(
              data['total_bytes']!, _totalBytesMeta));
    }
    if (data.containsKey('downloaded_bytes')) {
      context.handle(
          _downloadedBytesMeta,
          downloadedBytes.isAcceptableOrUnknown(
              data['downloaded_bytes']!, _downloadedBytesMeta));
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sourceUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_url'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      contentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_type'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      progress: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}progress'])!,
      totalBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_bytes']),
      downloadedBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}downloaded_bytes'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
    );
  }

  @override
  $DownloadsTable createAlias(String alias) {
    return $DownloadsTable(attachedDatabase, alias);
  }
}

class DownloadRow extends DataClass implements Insertable<DownloadRow> {
  final String id;
  final String sourceUrl;
  final String title;
  final String contentType;
  final String? localPath;
  final String status;
  final double progress;
  final int? totalBytes;
  final int downloadedBytes;
  final DateTime addedAt;
  final String? errorMessage;
  const DownloadRow(
      {required this.id,
      required this.sourceUrl,
      required this.title,
      required this.contentType,
      this.localPath,
      required this.status,
      required this.progress,
      this.totalBytes,
      required this.downloadedBytes,
      required this.addedAt,
      this.errorMessage});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_url'] = Variable<String>(sourceUrl);
    map['title'] = Variable<String>(title);
    map['content_type'] = Variable<String>(contentType);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    map['status'] = Variable<String>(status);
    map['progress'] = Variable<double>(progress);
    if (!nullToAbsent || totalBytes != null) {
      map['total_bytes'] = Variable<int>(totalBytes);
    }
    map['downloaded_bytes'] = Variable<int>(downloadedBytes);
    map['added_at'] = Variable<DateTime>(addedAt);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  DownloadsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsCompanion(
      id: Value(id),
      sourceUrl: Value(sourceUrl),
      title: Value(title),
      contentType: Value(contentType),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      status: Value(status),
      progress: Value(progress),
      totalBytes: totalBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(totalBytes),
      downloadedBytes: Value(downloadedBytes),
      addedAt: Value(addedAt),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory DownloadRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadRow(
      id: serializer.fromJson<String>(json['id']),
      sourceUrl: serializer.fromJson<String>(json['sourceUrl']),
      title: serializer.fromJson<String>(json['title']),
      contentType: serializer.fromJson<String>(json['contentType']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      status: serializer.fromJson<String>(json['status']),
      progress: serializer.fromJson<double>(json['progress']),
      totalBytes: serializer.fromJson<int?>(json['totalBytes']),
      downloadedBytes: serializer.fromJson<int>(json['downloadedBytes']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceUrl': serializer.toJson<String>(sourceUrl),
      'title': serializer.toJson<String>(title),
      'contentType': serializer.toJson<String>(contentType),
      'localPath': serializer.toJson<String?>(localPath),
      'status': serializer.toJson<String>(status),
      'progress': serializer.toJson<double>(progress),
      'totalBytes': serializer.toJson<int?>(totalBytes),
      'downloadedBytes': serializer.toJson<int>(downloadedBytes),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  DownloadRow copyWith(
          {String? id,
          String? sourceUrl,
          String? title,
          String? contentType,
          Value<String?> localPath = const Value.absent(),
          String? status,
          double? progress,
          Value<int?> totalBytes = const Value.absent(),
          int? downloadedBytes,
          DateTime? addedAt,
          Value<String?> errorMessage = const Value.absent()}) =>
      DownloadRow(
        id: id ?? this.id,
        sourceUrl: sourceUrl ?? this.sourceUrl,
        title: title ?? this.title,
        contentType: contentType ?? this.contentType,
        localPath: localPath.present ? localPath.value : this.localPath,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        totalBytes: totalBytes.present ? totalBytes.value : this.totalBytes,
        downloadedBytes: downloadedBytes ?? this.downloadedBytes,
        addedAt: addedAt ?? this.addedAt,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
      );
  DownloadRow copyWithCompanion(DownloadsCompanion data) {
    return DownloadRow(
      id: data.id.present ? data.id.value : this.id,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      title: data.title.present ? data.title.value : this.title,
      contentType:
          data.contentType.present ? data.contentType.value : this.contentType,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      status: data.status.present ? data.status.value : this.status,
      progress: data.progress.present ? data.progress.value : this.progress,
      totalBytes:
          data.totalBytes.present ? data.totalBytes.value : this.totalBytes,
      downloadedBytes: data.downloadedBytes.present
          ? data.downloadedBytes.value
          : this.downloadedBytes,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadRow(')
          ..write('id: $id, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('title: $title, ')
          ..write('contentType: $contentType, ')
          ..write('localPath: $localPath, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('addedAt: $addedAt, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sourceUrl, title, contentType, localPath,
      status, progress, totalBytes, downloadedBytes, addedAt, errorMessage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadRow &&
          other.id == this.id &&
          other.sourceUrl == this.sourceUrl &&
          other.title == this.title &&
          other.contentType == this.contentType &&
          other.localPath == this.localPath &&
          other.status == this.status &&
          other.progress == this.progress &&
          other.totalBytes == this.totalBytes &&
          other.downloadedBytes == this.downloadedBytes &&
          other.addedAt == this.addedAt &&
          other.errorMessage == this.errorMessage);
}

class DownloadsCompanion extends UpdateCompanion<DownloadRow> {
  final Value<String> id;
  final Value<String> sourceUrl;
  final Value<String> title;
  final Value<String> contentType;
  final Value<String?> localPath;
  final Value<String> status;
  final Value<double> progress;
  final Value<int?> totalBytes;
  final Value<int> downloadedBytes;
  final Value<DateTime> addedAt;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const DownloadsCompanion({
    this.id = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.title = const Value.absent(),
    this.contentType = const Value.absent(),
    this.localPath = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadsCompanion.insert({
    required String id,
    required String sourceUrl,
    required String title,
    required String contentType,
    this.localPath = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    required DateTime addedAt,
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sourceUrl = Value(sourceUrl),
        title = Value(title),
        contentType = Value(contentType),
        addedAt = Value(addedAt);
  static Insertable<DownloadRow> custom({
    Expression<String>? id,
    Expression<String>? sourceUrl,
    Expression<String>? title,
    Expression<String>? contentType,
    Expression<String>? localPath,
    Expression<String>? status,
    Expression<double>? progress,
    Expression<int>? totalBytes,
    Expression<int>? downloadedBytes,
    Expression<DateTime>? addedAt,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (title != null) 'title': title,
      if (contentType != null) 'content_type': contentType,
      if (localPath != null) 'local_path': localPath,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (downloadedBytes != null) 'downloaded_bytes': downloadedBytes,
      if (addedAt != null) 'added_at': addedAt,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadsCompanion copyWith(
      {Value<String>? id,
      Value<String>? sourceUrl,
      Value<String>? title,
      Value<String>? contentType,
      Value<String?>? localPath,
      Value<String>? status,
      Value<double>? progress,
      Value<int?>? totalBytes,
      Value<int>? downloadedBytes,
      Value<DateTime>? addedAt,
      Value<String?>? errorMessage,
      Value<int>? rowid}) {
    return DownloadsCompanion(
      id: id ?? this.id,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      title: title ?? this.title,
      contentType: contentType ?? this.contentType,
      localPath: localPath ?? this.localPath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      addedAt: addedAt ?? this.addedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (downloadedBytes.present) {
      map['downloaded_bytes'] = Variable<int>(downloadedBytes.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsCompanion(')
          ..write('id: $id, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('title: $title, ')
          ..write('contentType: $contentType, ')
          ..write('localPath: $localPath, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('addedAt: $addedAt, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WatchHistoryEntriesTable extends WatchHistoryEntries
    with TableInfo<$WatchHistoryEntriesTable, WatchHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchHistoryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentIdMeta =
      const VerificationMeta('contentId');
  @override
  late final GeneratedColumn<String> contentId = GeneratedColumn<String>(
      'content_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentTypeMeta =
      const VerificationMeta('contentType');
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
      'content_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _streamUrlMeta =
      const VerificationMeta('streamUrl');
  @override
  late final GeneratedColumn<String> streamUrl = GeneratedColumn<String>(
      'stream_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _posterUrlMeta =
      const VerificationMeta('posterUrl');
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
      'poster_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _positionSecondsMeta =
      const VerificationMeta('positionSeconds');
  @override
  late final GeneratedColumn<int> positionSeconds = GeneratedColumn<int>(
      'position_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastWatchedAtMeta =
      const VerificationMeta('lastWatchedAt');
  @override
  late final GeneratedColumn<DateTime> lastWatchedAt =
      GeneratedColumn<DateTime>('last_watched_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        contentId,
        contentType,
        title,
        streamUrl,
        posterUrl,
        positionSeconds,
        durationSeconds,
        lastWatchedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watch_history_entries';
  @override
  VerificationContext validateIntegrity(Insertable<WatchHistoryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('content_id')) {
      context.handle(_contentIdMeta,
          contentId.isAcceptableOrUnknown(data['content_id']!, _contentIdMeta));
    } else if (isInserting) {
      context.missing(_contentIdMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
          _contentTypeMeta,
          contentType.isAcceptableOrUnknown(
              data['content_type']!, _contentTypeMeta));
    } else if (isInserting) {
      context.missing(_contentTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('stream_url')) {
      context.handle(_streamUrlMeta,
          streamUrl.isAcceptableOrUnknown(data['stream_url']!, _streamUrlMeta));
    } else if (isInserting) {
      context.missing(_streamUrlMeta);
    }
    if (data.containsKey('poster_url')) {
      context.handle(_posterUrlMeta,
          posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta));
    }
    if (data.containsKey('position_seconds')) {
      context.handle(
          _positionSecondsMeta,
          positionSeconds.isAcceptableOrUnknown(
              data['position_seconds']!, _positionSecondsMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    }
    if (data.containsKey('last_watched_at')) {
      context.handle(
          _lastWatchedAtMeta,
          lastWatchedAt.isAcceptableOrUnknown(
              data['last_watched_at']!, _lastWatchedAtMeta));
    } else if (isInserting) {
      context.missing(_lastWatchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WatchHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchHistoryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      contentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_id'])!,
      contentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_type'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      streamUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stream_url'])!,
      posterUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}poster_url']),
      positionSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position_seconds'])!,
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds']),
      lastWatchedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_watched_at'])!,
    );
  }

  @override
  $WatchHistoryEntriesTable createAlias(String alias) {
    return $WatchHistoryEntriesTable(attachedDatabase, alias);
  }
}

class WatchHistoryRow extends DataClass implements Insertable<WatchHistoryRow> {
  final String id;
  final String contentId;
  final String contentType;
  final String title;
  final String streamUrl;
  final String? posterUrl;
  final int positionSeconds;
  final int? durationSeconds;
  final DateTime lastWatchedAt;
  const WatchHistoryRow(
      {required this.id,
      required this.contentId,
      required this.contentType,
      required this.title,
      required this.streamUrl,
      this.posterUrl,
      required this.positionSeconds,
      this.durationSeconds,
      required this.lastWatchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['content_id'] = Variable<String>(contentId);
    map['content_type'] = Variable<String>(contentType);
    map['title'] = Variable<String>(title);
    map['stream_url'] = Variable<String>(streamUrl);
    if (!nullToAbsent || posterUrl != null) {
      map['poster_url'] = Variable<String>(posterUrl);
    }
    map['position_seconds'] = Variable<int>(positionSeconds);
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['last_watched_at'] = Variable<DateTime>(lastWatchedAt);
    return map;
  }

  WatchHistoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return WatchHistoryEntriesCompanion(
      id: Value(id),
      contentId: Value(contentId),
      contentType: Value(contentType),
      title: Value(title),
      streamUrl: Value(streamUrl),
      posterUrl: posterUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(posterUrl),
      positionSeconds: Value(positionSeconds),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      lastWatchedAt: Value(lastWatchedAt),
    );
  }

  factory WatchHistoryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchHistoryRow(
      id: serializer.fromJson<String>(json['id']),
      contentId: serializer.fromJson<String>(json['contentId']),
      contentType: serializer.fromJson<String>(json['contentType']),
      title: serializer.fromJson<String>(json['title']),
      streamUrl: serializer.fromJson<String>(json['streamUrl']),
      posterUrl: serializer.fromJson<String?>(json['posterUrl']),
      positionSeconds: serializer.fromJson<int>(json['positionSeconds']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      lastWatchedAt: serializer.fromJson<DateTime>(json['lastWatchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'contentId': serializer.toJson<String>(contentId),
      'contentType': serializer.toJson<String>(contentType),
      'title': serializer.toJson<String>(title),
      'streamUrl': serializer.toJson<String>(streamUrl),
      'posterUrl': serializer.toJson<String?>(posterUrl),
      'positionSeconds': serializer.toJson<int>(positionSeconds),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'lastWatchedAt': serializer.toJson<DateTime>(lastWatchedAt),
    };
  }

  WatchHistoryRow copyWith(
          {String? id,
          String? contentId,
          String? contentType,
          String? title,
          String? streamUrl,
          Value<String?> posterUrl = const Value.absent(),
          int? positionSeconds,
          Value<int?> durationSeconds = const Value.absent(),
          DateTime? lastWatchedAt}) =>
      WatchHistoryRow(
        id: id ?? this.id,
        contentId: contentId ?? this.contentId,
        contentType: contentType ?? this.contentType,
        title: title ?? this.title,
        streamUrl: streamUrl ?? this.streamUrl,
        posterUrl: posterUrl.present ? posterUrl.value : this.posterUrl,
        positionSeconds: positionSeconds ?? this.positionSeconds,
        durationSeconds: durationSeconds.present
            ? durationSeconds.value
            : this.durationSeconds,
        lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      );
  WatchHistoryRow copyWithCompanion(WatchHistoryEntriesCompanion data) {
    return WatchHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      contentId: data.contentId.present ? data.contentId.value : this.contentId,
      contentType:
          data.contentType.present ? data.contentType.value : this.contentType,
      title: data.title.present ? data.title.value : this.title,
      streamUrl: data.streamUrl.present ? data.streamUrl.value : this.streamUrl,
      posterUrl: data.posterUrl.present ? data.posterUrl.value : this.posterUrl,
      positionSeconds: data.positionSeconds.present
          ? data.positionSeconds.value
          : this.positionSeconds,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      lastWatchedAt: data.lastWatchedAt.present
          ? data.lastWatchedAt.value
          : this.lastWatchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoryRow(')
          ..write('id: $id, ')
          ..write('contentId: $contentId, ')
          ..write('contentType: $contentType, ')
          ..write('title: $title, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('positionSeconds: $positionSeconds, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('lastWatchedAt: $lastWatchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, contentId, contentType, title, streamUrl,
      posterUrl, positionSeconds, durationSeconds, lastWatchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchHistoryRow &&
          other.id == this.id &&
          other.contentId == this.contentId &&
          other.contentType == this.contentType &&
          other.title == this.title &&
          other.streamUrl == this.streamUrl &&
          other.posterUrl == this.posterUrl &&
          other.positionSeconds == this.positionSeconds &&
          other.durationSeconds == this.durationSeconds &&
          other.lastWatchedAt == this.lastWatchedAt);
}

class WatchHistoryEntriesCompanion extends UpdateCompanion<WatchHistoryRow> {
  final Value<String> id;
  final Value<String> contentId;
  final Value<String> contentType;
  final Value<String> title;
  final Value<String> streamUrl;
  final Value<String?> posterUrl;
  final Value<int> positionSeconds;
  final Value<int?> durationSeconds;
  final Value<DateTime> lastWatchedAt;
  final Value<int> rowid;
  const WatchHistoryEntriesCompanion({
    this.id = const Value.absent(),
    this.contentId = const Value.absent(),
    this.contentType = const Value.absent(),
    this.title = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.positionSeconds = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.lastWatchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WatchHistoryEntriesCompanion.insert({
    required String id,
    required String contentId,
    required String contentType,
    required String title,
    required String streamUrl,
    this.posterUrl = const Value.absent(),
    this.positionSeconds = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    required DateTime lastWatchedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        contentId = Value(contentId),
        contentType = Value(contentType),
        title = Value(title),
        streamUrl = Value(streamUrl),
        lastWatchedAt = Value(lastWatchedAt);
  static Insertable<WatchHistoryRow> custom({
    Expression<String>? id,
    Expression<String>? contentId,
    Expression<String>? contentType,
    Expression<String>? title,
    Expression<String>? streamUrl,
    Expression<String>? posterUrl,
    Expression<int>? positionSeconds,
    Expression<int>? durationSeconds,
    Expression<DateTime>? lastWatchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contentId != null) 'content_id': contentId,
      if (contentType != null) 'content_type': contentType,
      if (title != null) 'title': title,
      if (streamUrl != null) 'stream_url': streamUrl,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (positionSeconds != null) 'position_seconds': positionSeconds,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (lastWatchedAt != null) 'last_watched_at': lastWatchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WatchHistoryEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? contentId,
      Value<String>? contentType,
      Value<String>? title,
      Value<String>? streamUrl,
      Value<String?>? posterUrl,
      Value<int>? positionSeconds,
      Value<int?>? durationSeconds,
      Value<DateTime>? lastWatchedAt,
      Value<int>? rowid}) {
    return WatchHistoryEntriesCompanion(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      title: title ?? this.title,
      streamUrl: streamUrl ?? this.streamUrl,
      posterUrl: posterUrl ?? this.posterUrl,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (contentId.present) {
      map['content_id'] = Variable<String>(contentId.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (streamUrl.present) {
      map['stream_url'] = Variable<String>(streamUrl.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (positionSeconds.present) {
      map['position_seconds'] = Variable<int>(positionSeconds.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (lastWatchedAt.present) {
      map['last_watched_at'] = Variable<DateTime>(lastWatchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('contentId: $contentId, ')
          ..write('contentType: $contentType, ')
          ..write('title: $title, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('positionSeconds: $positionSeconds, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('lastWatchedAt: $lastWatchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $ChannelsTable channels = $ChannelsTable(this);
  late final $MoviesTable movies = $MoviesTable(this);
  late final $SeriesTableTable seriesTable = $SeriesTableTable(this);
  late final $EpisodesTable episodes = $EpisodesTable(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  late final $WatchHistoryEntriesTable watchHistoryEntries =
      $WatchHistoryEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        playlists,
        channels,
        movies,
        seriesTable,
        episodes,
        downloads,
        watchHistoryEntries
      ];
}

typedef $$PlaylistsTableCreateCompanionBuilder = PlaylistsCompanion Function({
  required String id,
  required String name,
  required String type,
  Value<String?> m3uUrl,
  Value<String?> xtreamHost,
  Value<String?> xtreamUsername,
  Value<String?> xtreamPassword,
  required DateTime createdAt,
  Value<DateTime?> lastSyncedAt,
  Value<int> rowid,
});
typedef $$PlaylistsTableUpdateCompanionBuilder = PlaylistsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> type,
  Value<String?> m3uUrl,
  Value<String?> xtreamHost,
  Value<String?> xtreamUsername,
  Value<String?> xtreamPassword,
  Value<DateTime> createdAt,
  Value<DateTime?> lastSyncedAt,
  Value<int> rowid,
});

class $$PlaylistsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get m3uUrl => $state.composableBuilder(
      column: $state.table.m3uUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get xtreamHost => $state.composableBuilder(
      column: $state.table.xtreamHost,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get xtreamUsername => $state.composableBuilder(
      column: $state.table.xtreamUsername,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get xtreamPassword => $state.composableBuilder(
      column: $state.table.xtreamPassword,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastSyncedAt => $state.composableBuilder(
      column: $state.table.lastSyncedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$PlaylistsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get m3uUrl => $state.composableBuilder(
      column: $state.table.m3uUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get xtreamHost => $state.composableBuilder(
      column: $state.table.xtreamHost,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get xtreamUsername => $state.composableBuilder(
      column: $state.table.xtreamUsername,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get xtreamPassword => $state.composableBuilder(
      column: $state.table.xtreamPassword,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastSyncedAt => $state.composableBuilder(
      column: $state.table.lastSyncedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$PlaylistsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlaylistsTable,
    PlaylistRow,
    $$PlaylistsTableFilterComposer,
    $$PlaylistsTableOrderingComposer,
    $$PlaylistsTableCreateCompanionBuilder,
    $$PlaylistsTableUpdateCompanionBuilder,
    (PlaylistRow, BaseReferences<_$AppDatabase, $PlaylistsTable, PlaylistRow>),
    PlaylistRow,
    PrefetchHooks Function()> {
  $$PlaylistsTableTableManager(_$AppDatabase db, $PlaylistsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PlaylistsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PlaylistsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> m3uUrl = const Value.absent(),
            Value<String?> xtreamHost = const Value.absent(),
            Value<String?> xtreamUsername = const Value.absent(),
            Value<String?> xtreamPassword = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlaylistsCompanion(
            id: id,
            name: name,
            type: type,
            m3uUrl: m3uUrl,
            xtreamHost: xtreamHost,
            xtreamUsername: xtreamUsername,
            xtreamPassword: xtreamPassword,
            createdAt: createdAt,
            lastSyncedAt: lastSyncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String type,
            Value<String?> m3uUrl = const Value.absent(),
            Value<String?> xtreamHost = const Value.absent(),
            Value<String?> xtreamUsername = const Value.absent(),
            Value<String?> xtreamPassword = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlaylistsCompanion.insert(
            id: id,
            name: name,
            type: type,
            m3uUrl: m3uUrl,
            xtreamHost: xtreamHost,
            xtreamUsername: xtreamUsername,
            xtreamPassword: xtreamPassword,
            createdAt: createdAt,
            lastSyncedAt: lastSyncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlaylistsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlaylistsTable,
    PlaylistRow,
    $$PlaylistsTableFilterComposer,
    $$PlaylistsTableOrderingComposer,
    $$PlaylistsTableCreateCompanionBuilder,
    $$PlaylistsTableUpdateCompanionBuilder,
    (PlaylistRow, BaseReferences<_$AppDatabase, $PlaylistsTable, PlaylistRow>),
    PlaylistRow,
    PrefetchHooks Function()>;
typedef $$ChannelsTableCreateCompanionBuilder = ChannelsCompanion Function({
  required String id,
  required String playlistId,
  required String name,
  Value<String?> logoUrl,
  Value<String?> category,
  required String streamUrl,
  Value<bool> isFavorite,
  Value<int> rowid,
});
typedef $$ChannelsTableUpdateCompanionBuilder = ChannelsCompanion Function({
  Value<String> id,
  Value<String> playlistId,
  Value<String> name,
  Value<String?> logoUrl,
  Value<String?> category,
  Value<String> streamUrl,
  Value<bool> isFavorite,
  Value<int> rowid,
});

class $$ChannelsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get playlistId => $state.composableBuilder(
      column: $state.table.playlistId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get logoUrl => $state.composableBuilder(
      column: $state.table.logoUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get streamUrl => $state.composableBuilder(
      column: $state.table.streamUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isFavorite => $state.composableBuilder(
      column: $state.table.isFavorite,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$ChannelsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get playlistId => $state.composableBuilder(
      column: $state.table.playlistId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get logoUrl => $state.composableBuilder(
      column: $state.table.logoUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get streamUrl => $state.composableBuilder(
      column: $state.table.streamUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isFavorite => $state.composableBuilder(
      column: $state.table.isFavorite,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$ChannelsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChannelsTable,
    ChannelRow,
    $$ChannelsTableFilterComposer,
    $$ChannelsTableOrderingComposer,
    $$ChannelsTableCreateCompanionBuilder,
    $$ChannelsTableUpdateCompanionBuilder,
    (ChannelRow, BaseReferences<_$AppDatabase, $ChannelsTable, ChannelRow>),
    ChannelRow,
    PrefetchHooks Function()> {
  $$ChannelsTableTableManager(_$AppDatabase db, $ChannelsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ChannelsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ChannelsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> playlistId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> logoUrl = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String> streamUrl = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChannelsCompanion(
            id: id,
            playlistId: playlistId,
            name: name,
            logoUrl: logoUrl,
            category: category,
            streamUrl: streamUrl,
            isFavorite: isFavorite,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String playlistId,
            required String name,
            Value<String?> logoUrl = const Value.absent(),
            Value<String?> category = const Value.absent(),
            required String streamUrl,
            Value<bool> isFavorite = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChannelsCompanion.insert(
            id: id,
            playlistId: playlistId,
            name: name,
            logoUrl: logoUrl,
            category: category,
            streamUrl: streamUrl,
            isFavorite: isFavorite,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChannelsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChannelsTable,
    ChannelRow,
    $$ChannelsTableFilterComposer,
    $$ChannelsTableOrderingComposer,
    $$ChannelsTableCreateCompanionBuilder,
    $$ChannelsTableUpdateCompanionBuilder,
    (ChannelRow, BaseReferences<_$AppDatabase, $ChannelsTable, ChannelRow>),
    ChannelRow,
    PrefetchHooks Function()>;
typedef $$MoviesTableCreateCompanionBuilder = MoviesCompanion Function({
  required String id,
  required String playlistId,
  required String title,
  Value<String?> posterUrl,
  Value<String?> category,
  required String streamUrl,
  Value<String?> extension,
  Value<bool> isFavorite,
  Value<int> rowid,
});
typedef $$MoviesTableUpdateCompanionBuilder = MoviesCompanion Function({
  Value<String> id,
  Value<String> playlistId,
  Value<String> title,
  Value<String?> posterUrl,
  Value<String?> category,
  Value<String> streamUrl,
  Value<String?> extension,
  Value<bool> isFavorite,
  Value<int> rowid,
});

class $$MoviesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get playlistId => $state.composableBuilder(
      column: $state.table.playlistId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get posterUrl => $state.composableBuilder(
      column: $state.table.posterUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get streamUrl => $state.composableBuilder(
      column: $state.table.streamUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get extension => $state.composableBuilder(
      column: $state.table.extension,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isFavorite => $state.composableBuilder(
      column: $state.table.isFavorite,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$MoviesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get playlistId => $state.composableBuilder(
      column: $state.table.playlistId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get posterUrl => $state.composableBuilder(
      column: $state.table.posterUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get streamUrl => $state.composableBuilder(
      column: $state.table.streamUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get extension => $state.composableBuilder(
      column: $state.table.extension,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isFavorite => $state.composableBuilder(
      column: $state.table.isFavorite,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$MoviesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MoviesTable,
    MovieRow,
    $$MoviesTableFilterComposer,
    $$MoviesTableOrderingComposer,
    $$MoviesTableCreateCompanionBuilder,
    $$MoviesTableUpdateCompanionBuilder,
    (MovieRow, BaseReferences<_$AppDatabase, $MoviesTable, MovieRow>),
    MovieRow,
    PrefetchHooks Function()> {
  $$MoviesTableTableManager(_$AppDatabase db, $MoviesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$MoviesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$MoviesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> playlistId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> posterUrl = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String> streamUrl = const Value.absent(),
            Value<String?> extension = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MoviesCompanion(
            id: id,
            playlistId: playlistId,
            title: title,
            posterUrl: posterUrl,
            category: category,
            streamUrl: streamUrl,
            extension: extension,
            isFavorite: isFavorite,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String playlistId,
            required String title,
            Value<String?> posterUrl = const Value.absent(),
            Value<String?> category = const Value.absent(),
            required String streamUrl,
            Value<String?> extension = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MoviesCompanion.insert(
            id: id,
            playlistId: playlistId,
            title: title,
            posterUrl: posterUrl,
            category: category,
            streamUrl: streamUrl,
            extension: extension,
            isFavorite: isFavorite,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MoviesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MoviesTable,
    MovieRow,
    $$MoviesTableFilterComposer,
    $$MoviesTableOrderingComposer,
    $$MoviesTableCreateCompanionBuilder,
    $$MoviesTableUpdateCompanionBuilder,
    (MovieRow, BaseReferences<_$AppDatabase, $MoviesTable, MovieRow>),
    MovieRow,
    PrefetchHooks Function()>;
typedef $$SeriesTableTableCreateCompanionBuilder = SeriesTableCompanion
    Function({
  required String id,
  required String playlistId,
  required String title,
  Value<String?> posterUrl,
  Value<String?> category,
  Value<bool> isFavorite,
  Value<int> rowid,
});
typedef $$SeriesTableTableUpdateCompanionBuilder = SeriesTableCompanion
    Function({
  Value<String> id,
  Value<String> playlistId,
  Value<String> title,
  Value<String?> posterUrl,
  Value<String?> category,
  Value<bool> isFavorite,
  Value<int> rowid,
});

class $$SeriesTableTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SeriesTableTable> {
  $$SeriesTableTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get playlistId => $state.composableBuilder(
      column: $state.table.playlistId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get posterUrl => $state.composableBuilder(
      column: $state.table.posterUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isFavorite => $state.composableBuilder(
      column: $state.table.isFavorite,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SeriesTableTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SeriesTableTable> {
  $$SeriesTableTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get playlistId => $state.composableBuilder(
      column: $state.table.playlistId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get posterUrl => $state.composableBuilder(
      column: $state.table.posterUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isFavorite => $state.composableBuilder(
      column: $state.table.isFavorite,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$SeriesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SeriesTableTable,
    SeriesRow,
    $$SeriesTableTableFilterComposer,
    $$SeriesTableTableOrderingComposer,
    $$SeriesTableTableCreateCompanionBuilder,
    $$SeriesTableTableUpdateCompanionBuilder,
    (SeriesRow, BaseReferences<_$AppDatabase, $SeriesTableTable, SeriesRow>),
    SeriesRow,
    PrefetchHooks Function()> {
  $$SeriesTableTableTableManager(_$AppDatabase db, $SeriesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SeriesTableTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SeriesTableTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> playlistId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> posterUrl = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SeriesTableCompanion(
            id: id,
            playlistId: playlistId,
            title: title,
            posterUrl: posterUrl,
            category: category,
            isFavorite: isFavorite,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String playlistId,
            required String title,
            Value<String?> posterUrl = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SeriesTableCompanion.insert(
            id: id,
            playlistId: playlistId,
            title: title,
            posterUrl: posterUrl,
            category: category,
            isFavorite: isFavorite,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SeriesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SeriesTableTable,
    SeriesRow,
    $$SeriesTableTableFilterComposer,
    $$SeriesTableTableOrderingComposer,
    $$SeriesTableTableCreateCompanionBuilder,
    $$SeriesTableTableUpdateCompanionBuilder,
    (SeriesRow, BaseReferences<_$AppDatabase, $SeriesTableTable, SeriesRow>),
    SeriesRow,
    PrefetchHooks Function()>;
typedef $$EpisodesTableCreateCompanionBuilder = EpisodesCompanion Function({
  required String id,
  required String seriesId,
  required int seasonNumber,
  required int episodeNumber,
  required String title,
  required String streamUrl,
  Value<String?> extension,
  Value<int> rowid,
});
typedef $$EpisodesTableUpdateCompanionBuilder = EpisodesCompanion Function({
  Value<String> id,
  Value<String> seriesId,
  Value<int> seasonNumber,
  Value<int> episodeNumber,
  Value<String> title,
  Value<String> streamUrl,
  Value<String?> extension,
  Value<int> rowid,
});

class $$EpisodesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get seriesId => $state.composableBuilder(
      column: $state.table.seriesId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get seasonNumber => $state.composableBuilder(
      column: $state.table.seasonNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get episodeNumber => $state.composableBuilder(
      column: $state.table.episodeNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get streamUrl => $state.composableBuilder(
      column: $state.table.streamUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get extension => $state.composableBuilder(
      column: $state.table.extension,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$EpisodesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get seriesId => $state.composableBuilder(
      column: $state.table.seriesId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get seasonNumber => $state.composableBuilder(
      column: $state.table.seasonNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get episodeNumber => $state.composableBuilder(
      column: $state.table.episodeNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get streamUrl => $state.composableBuilder(
      column: $state.table.streamUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get extension => $state.composableBuilder(
      column: $state.table.extension,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$EpisodesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EpisodesTable,
    EpisodeRow,
    $$EpisodesTableFilterComposer,
    $$EpisodesTableOrderingComposer,
    $$EpisodesTableCreateCompanionBuilder,
    $$EpisodesTableUpdateCompanionBuilder,
    (EpisodeRow, BaseReferences<_$AppDatabase, $EpisodesTable, EpisodeRow>),
    EpisodeRow,
    PrefetchHooks Function()> {
  $$EpisodesTableTableManager(_$AppDatabase db, $EpisodesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$EpisodesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$EpisodesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> seriesId = const Value.absent(),
            Value<int> seasonNumber = const Value.absent(),
            Value<int> episodeNumber = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> streamUrl = const Value.absent(),
            Value<String?> extension = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EpisodesCompanion(
            id: id,
            seriesId: seriesId,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            title: title,
            streamUrl: streamUrl,
            extension: extension,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String seriesId,
            required int seasonNumber,
            required int episodeNumber,
            required String title,
            required String streamUrl,
            Value<String?> extension = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EpisodesCompanion.insert(
            id: id,
            seriesId: seriesId,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            title: title,
            streamUrl: streamUrl,
            extension: extension,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EpisodesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EpisodesTable,
    EpisodeRow,
    $$EpisodesTableFilterComposer,
    $$EpisodesTableOrderingComposer,
    $$EpisodesTableCreateCompanionBuilder,
    $$EpisodesTableUpdateCompanionBuilder,
    (EpisodeRow, BaseReferences<_$AppDatabase, $EpisodesTable, EpisodeRow>),
    EpisodeRow,
    PrefetchHooks Function()>;
typedef $$DownloadsTableCreateCompanionBuilder = DownloadsCompanion Function({
  required String id,
  required String sourceUrl,
  required String title,
  required String contentType,
  Value<String?> localPath,
  Value<String> status,
  Value<double> progress,
  Value<int?> totalBytes,
  Value<int> downloadedBytes,
  required DateTime addedAt,
  Value<String?> errorMessage,
  Value<int> rowid,
});
typedef $$DownloadsTableUpdateCompanionBuilder = DownloadsCompanion Function({
  Value<String> id,
  Value<String> sourceUrl,
  Value<String> title,
  Value<String> contentType,
  Value<String?> localPath,
  Value<String> status,
  Value<double> progress,
  Value<int?> totalBytes,
  Value<int> downloadedBytes,
  Value<DateTime> addedAt,
  Value<String?> errorMessage,
  Value<int> rowid,
});

class $$DownloadsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sourceUrl => $state.composableBuilder(
      column: $state.table.sourceUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get contentType => $state.composableBuilder(
      column: $state.table.contentType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get localPath => $state.composableBuilder(
      column: $state.table.localPath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get progress => $state.composableBuilder(
      column: $state.table.progress,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get totalBytes => $state.composableBuilder(
      column: $state.table.totalBytes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get downloadedBytes => $state.composableBuilder(
      column: $state.table.downloadedBytes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get addedAt => $state.composableBuilder(
      column: $state.table.addedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get errorMessage => $state.composableBuilder(
      column: $state.table.errorMessage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$DownloadsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sourceUrl => $state.composableBuilder(
      column: $state.table.sourceUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get contentType => $state.composableBuilder(
      column: $state.table.contentType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get localPath => $state.composableBuilder(
      column: $state.table.localPath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get progress => $state.composableBuilder(
      column: $state.table.progress,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get totalBytes => $state.composableBuilder(
      column: $state.table.totalBytes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get downloadedBytes => $state.composableBuilder(
      column: $state.table.downloadedBytes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get addedAt => $state.composableBuilder(
      column: $state.table.addedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get errorMessage => $state.composableBuilder(
      column: $state.table.errorMessage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$DownloadsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DownloadsTable,
    DownloadRow,
    $$DownloadsTableFilterComposer,
    $$DownloadsTableOrderingComposer,
    $$DownloadsTableCreateCompanionBuilder,
    $$DownloadsTableUpdateCompanionBuilder,
    (DownloadRow, BaseReferences<_$AppDatabase, $DownloadsTable, DownloadRow>),
    DownloadRow,
    PrefetchHooks Function()> {
  $$DownloadsTableTableManager(_$AppDatabase db, $DownloadsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$DownloadsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$DownloadsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sourceUrl = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> contentType = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<double> progress = const Value.absent(),
            Value<int?> totalBytes = const Value.absent(),
            Value<int> downloadedBytes = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DownloadsCompanion(
            id: id,
            sourceUrl: sourceUrl,
            title: title,
            contentType: contentType,
            localPath: localPath,
            status: status,
            progress: progress,
            totalBytes: totalBytes,
            downloadedBytes: downloadedBytes,
            addedAt: addedAt,
            errorMessage: errorMessage,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String sourceUrl,
            required String title,
            required String contentType,
            Value<String?> localPath = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<double> progress = const Value.absent(),
            Value<int?> totalBytes = const Value.absent(),
            Value<int> downloadedBytes = const Value.absent(),
            required DateTime addedAt,
            Value<String?> errorMessage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DownloadsCompanion.insert(
            id: id,
            sourceUrl: sourceUrl,
            title: title,
            contentType: contentType,
            localPath: localPath,
            status: status,
            progress: progress,
            totalBytes: totalBytes,
            downloadedBytes: downloadedBytes,
            addedAt: addedAt,
            errorMessage: errorMessage,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DownloadsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DownloadsTable,
    DownloadRow,
    $$DownloadsTableFilterComposer,
    $$DownloadsTableOrderingComposer,
    $$DownloadsTableCreateCompanionBuilder,
    $$DownloadsTableUpdateCompanionBuilder,
    (DownloadRow, BaseReferences<_$AppDatabase, $DownloadsTable, DownloadRow>),
    DownloadRow,
    PrefetchHooks Function()>;
typedef $$WatchHistoryEntriesTableCreateCompanionBuilder
    = WatchHistoryEntriesCompanion Function({
  required String id,
  required String contentId,
  required String contentType,
  required String title,
  required String streamUrl,
  Value<String?> posterUrl,
  Value<int> positionSeconds,
  Value<int?> durationSeconds,
  required DateTime lastWatchedAt,
  Value<int> rowid,
});
typedef $$WatchHistoryEntriesTableUpdateCompanionBuilder
    = WatchHistoryEntriesCompanion Function({
  Value<String> id,
  Value<String> contentId,
  Value<String> contentType,
  Value<String> title,
  Value<String> streamUrl,
  Value<String?> posterUrl,
  Value<int> positionSeconds,
  Value<int?> durationSeconds,
  Value<DateTime> lastWatchedAt,
  Value<int> rowid,
});

class $$WatchHistoryEntriesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $WatchHistoryEntriesTable> {
  $$WatchHistoryEntriesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get contentId => $state.composableBuilder(
      column: $state.table.contentId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get contentType => $state.composableBuilder(
      column: $state.table.contentType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get streamUrl => $state.composableBuilder(
      column: $state.table.streamUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get posterUrl => $state.composableBuilder(
      column: $state.table.posterUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get positionSeconds => $state.composableBuilder(
      column: $state.table.positionSeconds,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get durationSeconds => $state.composableBuilder(
      column: $state.table.durationSeconds,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastWatchedAt => $state.composableBuilder(
      column: $state.table.lastWatchedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$WatchHistoryEntriesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $WatchHistoryEntriesTable> {
  $$WatchHistoryEntriesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get contentId => $state.composableBuilder(
      column: $state.table.contentId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get contentType => $state.composableBuilder(
      column: $state.table.contentType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get streamUrl => $state.composableBuilder(
      column: $state.table.streamUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get posterUrl => $state.composableBuilder(
      column: $state.table.posterUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get positionSeconds => $state.composableBuilder(
      column: $state.table.positionSeconds,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get durationSeconds => $state.composableBuilder(
      column: $state.table.durationSeconds,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastWatchedAt => $state.composableBuilder(
      column: $state.table.lastWatchedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$WatchHistoryEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WatchHistoryEntriesTable,
    WatchHistoryRow,
    $$WatchHistoryEntriesTableFilterComposer,
    $$WatchHistoryEntriesTableOrderingComposer,
    $$WatchHistoryEntriesTableCreateCompanionBuilder,
    $$WatchHistoryEntriesTableUpdateCompanionBuilder,
    (
      WatchHistoryRow,
      BaseReferences<_$AppDatabase, $WatchHistoryEntriesTable, WatchHistoryRow>
    ),
    WatchHistoryRow,
    PrefetchHooks Function()> {
  $$WatchHistoryEntriesTableTableManager(
      _$AppDatabase db, $WatchHistoryEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$WatchHistoryEntriesTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$WatchHistoryEntriesTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> contentId = const Value.absent(),
            Value<String> contentType = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> streamUrl = const Value.absent(),
            Value<String?> posterUrl = const Value.absent(),
            Value<int> positionSeconds = const Value.absent(),
            Value<int?> durationSeconds = const Value.absent(),
            Value<DateTime> lastWatchedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WatchHistoryEntriesCompanion(
            id: id,
            contentId: contentId,
            contentType: contentType,
            title: title,
            streamUrl: streamUrl,
            posterUrl: posterUrl,
            positionSeconds: positionSeconds,
            durationSeconds: durationSeconds,
            lastWatchedAt: lastWatchedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String contentId,
            required String contentType,
            required String title,
            required String streamUrl,
            Value<String?> posterUrl = const Value.absent(),
            Value<int> positionSeconds = const Value.absent(),
            Value<int?> durationSeconds = const Value.absent(),
            required DateTime lastWatchedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              WatchHistoryEntriesCompanion.insert(
            id: id,
            contentId: contentId,
            contentType: contentType,
            title: title,
            streamUrl: streamUrl,
            posterUrl: posterUrl,
            positionSeconds: positionSeconds,
            durationSeconds: durationSeconds,
            lastWatchedAt: lastWatchedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WatchHistoryEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WatchHistoryEntriesTable,
    WatchHistoryRow,
    $$WatchHistoryEntriesTableFilterComposer,
    $$WatchHistoryEntriesTableOrderingComposer,
    $$WatchHistoryEntriesTableCreateCompanionBuilder,
    $$WatchHistoryEntriesTableUpdateCompanionBuilder,
    (
      WatchHistoryRow,
      BaseReferences<_$AppDatabase, $WatchHistoryEntriesTable, WatchHistoryRow>
    ),
    WatchHistoryRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db, _db.playlists);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db, _db.channels);
  $$MoviesTableTableManager get movies =>
      $$MoviesTableTableManager(_db, _db.movies);
  $$SeriesTableTableTableManager get seriesTable =>
      $$SeriesTableTableTableManager(_db, _db.seriesTable);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db, _db.episodes);
  $$DownloadsTableTableManager get downloads =>
      $$DownloadsTableTableManager(_db, _db.downloads);
  $$WatchHistoryEntriesTableTableManager get watchHistoryEntries =>
      $$WatchHistoryEntriesTableTableManager(_db, _db.watchHistoryEntries);
}
