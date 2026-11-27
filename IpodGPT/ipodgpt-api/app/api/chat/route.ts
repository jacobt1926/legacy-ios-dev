
import OpenAI from "openai";

export async function GET() {
  return Response.json({
    status: "online",
    service: "PocketGPT"
  });
}

export async function POST(request: Request) {
  const token = process.env.IPODGPT_TOKEN;

  if (
    !token ||
    request.headers.get("authorization") !== `Bearer ${token}`
  ) {
    return Response.json(
      { error: "Unauthorized" },
      { status: 401 }
    );
  }

  try {
    const { message } = await request.json();

    if (
      typeof message !== "string" ||
      !message.trim() ||
      message.length > 4000
    ) {
      return Response.json(
        { error: "Invalid message" },
        { status: 400 }
      );
    }

    const openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY
    });

    const response = await openai.responses.create({
      model: process.env.OPENAI_MODEL || "gpt-6-luna",
      instructions:
        "You are PocketGPT, an AI assistant running on a legacy iPod Touch. Provide helpful, concise responses suitable for a small screen.",
      input: message,
      max_output_tokens: 1000,
      store: false
    });

    return Response.json({
      reply: response.output_text
    });

  } catch (error) {
    console.error(error);

    return Response.json(
      { error: "Failed to generate response" },
      { status: 500 }
    );
  }
}
