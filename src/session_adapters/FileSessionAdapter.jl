module FileSessionAdapter

using Nullables
using Genie.Sessions, Genie, Genie.Loggers, Genie.Configuration
using Serialization

const SESSION_FOLDER = Genie.config.session_folder

"""
    write(session::Sessions.Session) :: Sessions.Session

Persists the `Session` object to the file system, using the configured sessions folder and returns it.
"""
function write(session::Sessions.Session) :: Sessions.Session
  try
    open(joinpath(SESSION_FOLDER, session.id), "w") do (io)
      serialize(io, session)
    end
  catch ex
    log("Error when serializing session in $(@__FILE__):$(@__LINE__)", :err)
    log(string(ex), :err)
    log("$(@__FILE__):$(@__LINE__)", :err)

    Genie.Configuration.is_prod() && rethrow(ex)
  end

  session
end


"""
    read(session_id::Union{String,Symbol}) :: Nullable{Sessions.Session}
    read(session::Sessions.Session) :: Nullable{Sessions.Session}

Attempts to read from file the session object serialized as `session_id`.
"""
function read(session_id::Union{String,Symbol}) :: Nullable{Sessions.Session}
  try
    isfile(joinpath(SESSION_FOLDER, session_id)) || return Nullable{Sessions.Session}(write(Session(session_id)))
  catch ex
    log("Can't check session file", :err)
    log(string(ex), :err)
    log("$(@__FILE__):$(@__LINE__)", :err)

    Nullable{Sessions.Session}(write(Session(session_id)))
  end

  try
    session = open(joinpath(SESSION_FOLDER, session_id), "r") do (io)
      deserialize(io)
    end

    Nullable{Sessions.Session}(session)
  catch ex
    log("Can't read session", :err)
    log(string(ex), :err)
    log("$(@__FILE__):$(@__LINE__)", :err)

    Nullable{Sessions.Session}(write(Session(session_id)))
  end
end
function read(session::Sessions.Session) :: Nullable{Sessions.Session}
  read(session.id)
end

end
