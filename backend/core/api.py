from rest_framework.response import Response


class ApiResponseMixin:
    def success_response(self, *, data=None, message="", status_code=200):
        return Response(
            {
                "success": True,
                "data": data if data is not None else {},
                "message": message,
            },
            status=status_code,
        )

    def error_response(self, *, data=None, message="", status_code=400):
        return Response(
            {
                "success": False,
                "data": data if data is not None else {},
                "message": message,
            },
            status=status_code,
        )
