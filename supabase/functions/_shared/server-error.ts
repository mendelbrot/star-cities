export class ServerError extends Error {
  statusCode: number;
  constructor(message: string, status: number ) {
    super(message);
    this.statusCode = status;
    this.name = "ServerError";
  }
}
