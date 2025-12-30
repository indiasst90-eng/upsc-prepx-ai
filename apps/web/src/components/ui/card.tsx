import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"

import { cn } from "@/lib/utils"

const cardVariants = cva(
  "rounded-2xl transition-all duration-200",
  {
    variants: {
      variant: {
        // Glassmorphic card (default)
        default: [
          "bg-white/5 backdrop-blur-[24px]",
          "border border-white/10",
          "shadow-[0_4px_20px_rgba(0,0,0,0.2)]",
          "hover:bg-white/8",
          "hover:shadow-[0_4px_20px_rgba(0,243,255,0.2)]"
        ],
        // Neumorphic card
        neuro: [
          "bg-[rgba(20,20,35,0.5)]",
          "shadow-[6px_6px_12px_var(--neuro-shadow-dark),-4px_-4px_8px_var(--neuro-shadow-light)]",
          "hover:shadow-[8px_8px_16px_var(--neuro-shadow-dark),-6px_-6px_12px_var(--neuro-shadow-light)]"
        ],
        // Solid background card
        solid: [
          "bg-card border border-border",
          "shadow-sm",
          "hover:shadow-md"
        ],
        // Neon accent card
        neon: [
          "bg-gradient-to-br from-[var(--neon-blue)]/10 to-[var(--neon-purple)]/10",
          "border border-[var(--neon-blue)]/30",
          "shadow-[0_0_20px_rgba(0,243,255,0.2)]",
          "hover:shadow-[0_0_30px_rgba(0,243,255,0.3)]"
        ]
      }
    },
    defaultVariants: {
      variant: "default"
    }
  }
)

export interface CardProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof cardVariants> {}

const Card = React.forwardRef<HTMLDivElement, CardProps>(
  ({ className, variant, ...props }, ref) => (
    <div
      ref={ref}
      className={cn(cardVariants({ variant }), "text-card-foreground", className)}
      {...props}
    />
  )
)
Card.displayName = "Card"

const CardHeader = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn("flex flex-col space-y-1.5 p-6", className)}
    {...props}
  />
))
CardHeader.displayName = "CardHeader"

const CardTitle = React.forwardRef<
  HTMLParagraphElement,
  React.HTMLAttributes<HTMLHeadingElement>
>(({ className, ...props }, ref) => (
  <h3
    ref={ref}
    className={cn(
      "text-2xl font-semibold leading-none tracking-tight",
      className
    )}
    {...props}
  />
))
CardTitle.displayName = "CardTitle"

const CardDescription = React.forwardRef<
  HTMLParagraphElement,
  React.HTMLAttributes<HTMLParagraphElement>
>(({ className, ...props }, ref) => (
  <p
    ref={ref}
    className={cn("text-sm text-muted-foreground", className)}
    {...props}
  />
))
CardDescription.displayName = "CardDescription"

const CardContent = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div ref={ref} className={cn("p-6 pt-0", className)} {...props} />
))
CardContent.displayName = "CardContent"

const CardFooter = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn("flex items-center p-6 pt-0", className)}
    {...props}
  />
))
CardFooter.displayName = "CardFooter"

export { Card, CardHeader, CardFooter, CardTitle, CardDescription, CardContent }
