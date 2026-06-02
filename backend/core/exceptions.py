from rest_framework.views import exception_handler


def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is None:
        return response

    message = "Request failed."
    payload = {}

    if isinstance(response.data, dict):
        detail = response.data.get("detail")
        if detail is not None and len(response.data) == 1:
            message = str(detail)
        else:
            payload = response.data
            message = str(detail) if detail is not None else message
    else:
        payload = {"errors": response.data}

    response.data = {
        "success": False,
        "data": payload,
        "message": message,
    }
    return response
