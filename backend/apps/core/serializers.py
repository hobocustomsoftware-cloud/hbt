from rest_framework import serializers


class EmptySerializer(serializers.Serializer):
    pass


class HealthSerializer(serializers.Serializer):
    status = serializers.CharField()
    service = serializers.CharField(required=False)
    api_version = serializers.CharField(required=False)
    database = serializers.CharField(required=False)


class CountSerializer(serializers.Serializer):
    unread_count = serializers.IntegerField(min_value=0)


class DetailSerializer(serializers.Serializer):
    detail = serializers.CharField()
