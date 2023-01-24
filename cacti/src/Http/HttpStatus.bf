using System;

namespace Cacti.Http;

// https://github.com/thibmo/Beef-Net/blob/main/src/Http.bf

enum HttpStatus {
	case Continue                = 100;
	case SwitchingProtocols      = 101;
	case Processing              = 102;
	case EarlyHints              = 103;
	
	case OK                      = 200;
	case Created                 = 201;
	case Accepted                = 202;
	case NonAuthInfo             = 203;
	case NoContent               = 204;
	case ResetContent            = 205;
	case PartialContent          = 206;
	case MultiStatus             = 207;
	case AlreadyReported         = 208;
	
	case MultipleChoices         = 300;
	case MovedPermanently        = 301;
	case Found                   = 302;
	case SeeOther                = 303;
	case NotModified             = 304;
	case UseProxy                = 305;
	case SwitchProxy             = 306;
	case TempRedirect            = 307;
	case PermRedirect            = 308;
	
	case BadRequest              = 400;
	case Unauthorized            = 401;
	case PaymentRequired         = 402;
	case Forbidden               = 403;
	case NotFound                = 404;
	case MethodNotAllowed        = 405;
	case NotAcceptable           = 406;
	case ProxyAuthRequired       = 407;
	case RequestTimeout          = 408;
	case Conflict                = 409;
	case Gone                    = 410;
	case LengthRequired          = 411;
	case PreconditionFailed      = 412;
	case PayloadTooLarge         = 413;
	case RequestTooLong          = 414;
	case UnsupportedMediaType    = 415;
	case RangeNotSatisfiable     = 416;
	case ExpectationsFailed      = 417;
	case ImATeapot               = 418;
	case MisdirectedRequest      = 421;
	case UnprocessableEntity     = 422;
	case Locked                  = 423;
	case FailedDependency        = 424;
	case TooEarly                = 425;
	case UpgradeRequired         = 426;
	case PreconditionRequired    = 428;
	case TooManyRequests         = 429;
	case ReqHdrFieldsTooLarge    = 431;
	case UnavailForLegalReasons  = 451;
	
	case InternalError           = 500;
	case NotImplemented          = 501;
	case BadGateway              = 502;
	case ServiceUnavailable      = 503;
	case GatewayTimeout          = 504;
	case HttpVersionNotSupported = 505;
	case VariantAlsoNegotiates   = 506;
	case InsufficientStorage     = 507;
	case LoopDetected            = 508;
	case NotExtended             = 510;
	case NetworkAuthRequired     = 511;

	public static Result<Self> FromCode(int code) {
		for (let status in Enum.GetValues<Self>()) {
			if (status.Underlying == code) return status;
		}

		return .Err;
	}

	public StringView Name { get {
		switch (this) {
		case .Continue:                return "Continue";
		case .SwitchingProtocols:      return "Switching Protocols";
		case .Processing:              return "Processing";
		case .EarlyHints:              return "Early Hints";

		case .OK:                      return "OK";
		case .Created:                 return "Created";
		case .Accepted:                return "Accepted";
		case .NonAuthInfo:             return "Non-Authoritative Information";
		case .NoContent:               return "No Content";
		case .ResetContent:            return "Reset Content";
		case .PartialContent:          return "Partial Content";
		case .MultiStatus:             return "Multi-Status";
		case .AlreadyReported:         return "Already Reported";

		case .MultipleChoices:         return "Multiple Choices";
		case .MovedPermanently:        return "Moved Permanently";
		case .Found:                   return "Found";
		case .SeeOther:                return "See Other";
		case .NotModified:             return "Not Modified";
		case .UseProxy:                return "Use Proxy";
		case .SwitchProxy:             return "Switch Proxy";
		case .TempRedirect:            return "Temporary Redirect";
		case .PermRedirect:            return "Permanent Redirect";

		case .BadRequest:              return "Bad Request";
		case .Unauthorized:            return "Unauthorized";
		case .PaymentRequired:         return "Payment Required";
		case .Forbidden:               return "Forbidden";
		case .NotFound:                return "Not Found";
		case .MethodNotAllowed:        return "Method Not Allowed";
		case .NotAcceptable:           return "Not Acceptable";
		case .ProxyAuthRequired:       return "Proxy Authentication Required";
		case .RequestTimeout:          return "Request Timeout";
		case .Conflict:                return "Conflict";
		case .Gone:                    return "Gone";
		case .LengthRequired:          return "Length Required";
		case .PreconditionFailed:      return "Precondition Failed";
		case .PayloadTooLarge:         return "Payload Too Large";
		case .RequestTooLong:          return "Request Too Long";
		case .UnsupportedMediaType:    return "Unsupported Media Type";
		case .RangeNotSatisfiable:     return "Range Not Satisfiable";
		case .ExpectationsFailed:      return "Expectations Failed";
		case .ImATeapot:               return "I'm A Teapot \u{1FAD6}";
		case .MisdirectedRequest:      return "Misdirected Request";
		case .UnprocessableEntity:     return "Unprocessable Entity";
		case .Locked:                  return "Locked";
		case .FailedDependency:        return "Failed Dependency";
		case .TooEarly:                return "Too Early";
		case .UpgradeRequired:         return "Upgrade Required";
		case .PreconditionRequired:    return "Precondition Required";
		case .TooManyRequests:         return "Too Many Requests";
		case .ReqHdrFieldsTooLarge:    return "Request Header Fields Too Large";
		case .UnavailForLegalReasons:  return "Unavailable For Legal Reasons";

		case .InternalError:           return "Internal Server Error";
		case .NotImplemented:          return "Method Not Implemented";
		case .BadGateway:              return "Bad Gateway";
		case .ServiceUnavailable:      return "Service Unavailable";
		case .GatewayTimeout:          return "Gateway Timeout";
		case .HttpVersionNotSupported: return "HTTP Version Not Supported";
		case .VariantAlsoNegotiates:   return "Variant Also Negotiates";
		case .InsufficientStorage:     return "Insufficient Storage";
		case .LoopDetected:            return "Loop Detected";
		case .NotExtended:             return "Not Extended";
		case .NetworkAuthRequired:     return "Network Authentication Required";
		}
	} }

	public override void ToString(String buf) {
		buf.Append(Name);
	}
}