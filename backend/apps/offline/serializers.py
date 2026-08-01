from rest_framework import serializers

from .models import AuthorizationSnapshot, Device, SyncChange, SyncOperation


class DeviceSerializer(serializers.ModelSerializer):
    push_token = serializers.CharField(
        write_only=True, required=False, allow_blank=True
    )
    class Meta:
        model = Device
        fields = (
            "id",
            "installation_id",
            "platform",
            "app_id",
            "app_version",
            "device_name",
            "status",
            "push_token",
            "last_seen_at",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "status", "last_seen_at", "created_at", "updated_at")
        extra_kwargs = {"push_token": {"write_only": True, "required": False}}

    def create(self, validated_data):
        token = validated_data.pop("push_token", "")
        device = Device(**validated_data)
        device.set_push_token(token)
        device.save()
        return device

    def update(self, instance, validated_data):
        token = validated_data.pop("push_token", None)
        for field, value in validated_data.items():
            setattr(instance, field, value)
        if token is not None:
            instance.set_push_token(token)
        instance.save()
        return instance


class AuthorizationSnapshotSerializer(serializers.ModelSerializer):
    class Meta:
        model = AuthorizationSnapshot
        fields = (
            "id",
            "device",
            "organization",
            "membership",
            "permissions",
            "scopes",
            "issued_at",
            "expires_at",
            "revoked_at",
        )
        read_only_fields = fields


class SyncChangeSerializer(serializers.ModelSerializer):
    class Meta:
        model = SyncChange
        fields = "__all__"
        read_only_fields = (
            "sequence", "organization", "resource_type", "resource_id",
            "operation", "version", "payload", "occurred_at",
        )


class SyncOperationInputSerializer(serializers.Serializer):
    client_operation_id = serializers.UUIDField()
    operation_type = serializers.CharField(max_length=100)
    payload = serializers.JSONField()


class SyncOperationSerializer(serializers.ModelSerializer):
    class Meta:
        model = SyncOperation
        fields = (
            "id",
            "client_operation_id",
            "operation_type",
            "status",
            "response_payload",
            "error_code",
            "created_at",
            "updated_at",
        )
        read_only_fields = fields


class SyncCapabilitiesSerializer(serializers.Serializer):
    protocol_version = serializers.IntegerField()
    authorization_snapshot_hours = serializers.IntegerField()
    supported_upload_operations = serializers.ListField(
        child=serializers.CharField()
    )
    delta_download = serializers.BooleanField()
    manual_sync = serializers.BooleanField()
    max_batch_size = serializers.IntegerField()


class SyncPushResponseSerializer(serializers.Serializer):
    operations = SyncOperationSerializer(many=True)


class SyncPullResponseSerializer(serializers.Serializer):
    changes = SyncChangeSerializer(many=True)
    next_cursor = serializers.IntegerField()
    has_more = serializers.BooleanField()
    server_time = serializers.DateTimeField()
