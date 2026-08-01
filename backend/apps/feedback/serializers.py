from rest_framework import serializers

from .models import Feedback


class FeedbackSerializer(serializers.ModelSerializer):
    class Meta:
        model = Feedback
        fields = (
            "id", "organization", "source", "category", "title", "message",
            "language", "status", "priority", "app_version", "device_context",
            "owner_response", "reviewed_by", "reviewed_at", "created_at",
            "updated_at",
        )
        read_only_fields = (
            "id", "status", "priority", "owner_response", "reviewed_by",
            "reviewed_at", "created_at", "updated_at",
        )
        extra_kwargs = {
            "device_context": {"write_only": True, "required": False},
        }

    def validate(self, data):
        if data.get("category") == Feedback.Category.SECURITY:
            # Security details are private and never exposed in public listings.
            data["priority"] = "high"
        return data

    def create(self, data):
        return Feedback.objects.create(
            submitted_by=self.context["request"].user, **data
        )


class FeedbackTriageSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=Feedback.Status.choices)
    priority = serializers.ChoiceField(
        choices=("low", "normal", "high", "urgent")
    )
    owner_response = serializers.CharField(required=False, allow_blank=True)

