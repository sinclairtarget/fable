class FableError(Exception):
    pass


class NotInitializedError(FableError):
    def __str__(self):
        return "not a Fable repository"
